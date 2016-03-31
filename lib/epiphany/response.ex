defmodule Epiphany.Response do
  @moduledoc """
  This module contains functions to deserialize frame bodies based on
  operation code.  Each function returns a tuple containing a symbol with the
  type of response, and the decoded body (which may be empty, or another tuple
  depending on the response type).
  """

  alias Epiphany.Frame
  alias Epiphany.Frame.Body

  use Bitwise

  def decode(%Frame{stream: stream, body: body, op_code: op_code}) do
    {stream, decode(op_code, body)}
  end

  def decode(0x00, error) do
    # Add support to read the rest of the body
    {:ok, code, rest} = Body.read_int(error)
    {:ok, msg, _} = Body.read_string(rest)
    {:error, code, msg}
  end

  def decode(0x02, <<>>), do: :ready

  # Authenticate

  def decode(0x06, body) do
    {:ok, supported, _} = Body.read_string_multimap(body)
    {:supported, supported}
  end

  def decode(0x08, body) do
    {:ok, kind, content} = Body.read_int(body)
    {:result, decode_result(kind, content)}
  end

  defp decode_result(0x0001, <<>>), do: :void

  defp decode_result(0x0002, rows) when is_binary(rows) do
    {col_count, p_state, names, rest} = decode_result_metadata(rows)
    {:ok, row_count, content} = Body.read_int(rest)

    {all_rows, _} = if row_count > 0 do
      Enum.reduce((1..row_count), {[], content}, fn(_, {row_a, data}) ->
        {row, after_row} = decode_row(data, col_count, names)
        {[row|row_a], after_row}
      end )
    else
      {[], content}
    end

    %Epiphany.Result{rows: Enum.reverse(all_rows), row_count: row_count,
      paging_state: p_state}
  end

  defp decode_result(0x0003, body) do
    {:ok, ks, _} = Body.read_string(body)
    {:set_keyspace, ks}
  end

  defp decode_result(0x0004, body) do
    {:ok, id, _} = Body.read_short_bytes(body)
    {:prepared, id}
  end

  defp decode_result(0x0005, body) do
    {:ok, type, after_type} = Body.read_string(body)
    {:ok, target, after_target} = Body.read_string(after_type)
    {:ok, options, _} = Body.read_string(after_target)
    # May be a last string depending on the target
    {:schema_changed, type, target, options}
  end

  defp decode_row(data, col_count, names) do
    {all_cols, rest} =
      Enum.reduce((1..col_count), {[], data}, fn(_, {col_a, d}) ->
        {:ok, item, after_item} = Body.read_bytes(d)
        {[item|col_a], after_item}
        end )

    {
     %Epiphany.Result.Row{
       columns: Enum.reverse(all_cols),
       col_count: col_count,
       names: names},
     rest
    }
  end

  defp decode_result_metadata(body) do
    {:ok, flags, after_flags} = Body.read_int(body)
    {:ok, column_count, after_c_count} = Body.read_int(after_flags)

    {_, p_state, after_p_state} =
    if (flags &&& 0x0002) == 0x0002 do
      Body.read_bytes(after_c_count)
    else
      {:ok, nil, after_c_count}
    end

    {names, after_opt_meta} =
      read_optional_metadata(flags, after_p_state, column_count)

    {column_count, p_state, names, after_opt_meta}
  end

  defp read_optional_metadata(flags, data, _)
    when (flags &&& 0x0004) == 0x0004, do: {nil, data}

  defp read_optional_metadata(flags, data, col_count) do

    has_global_spec = (flags &&& 0x0001) == 0x0001

    after_global_t_spec =
      if has_global_spec do
        {:ok, ks, after_ks} = Body.read_string(data)
        {:ok, table, after_global_spec} = Body.read_string(after_ks)
        # We don't store that for now
        after_global_spec
      else
        data
      end

    {names, rest} =
      Enum.reduce((1..col_count), {[], after_global_t_spec}, fn(_, {col_a, d}) ->
        data =
          if !has_global_spec do
            {:ok, ksname, after_ksname} = Body.read_string(d)
            {:ok, tname, after_tname} = Body.read_string(d)
            after_tname
          else
            d
          end
        {:ok, col_name, after_name} = Body.read_string(data)
        {:ok, _type, after_type} = Body.read_short(after_name)
        # FIXME handle case where option has a value (list, custom, etc)
        {[col_name|col_a], after_type}
      end )
    {Enum.reverse(names), rest}
  end


  # Event

  # Auth_Challenge

  # Auth_Success

end