defmodule Epiphany.Request do
  @moduledoc """
  This module provides convenient functions to create request frames.  It
   provides functions for each type of request, and returns the operation code
   and the serialized body to be inserted in the frame object.
  """

  alias Epiphany.Frame.Body

  use Bitwise

  def startup(), do: {0x01, Body.write_string_map(%{"CQL_VERSION" => "3.0.0"})}

  # Auth_response

  def options(), do: {0x05, <<>>}

  def query(q, consistency \\ :one, values \\ nil, page_size \\ nil,
    paging_state \\ nil, serial_consistency \\ nil, skip_metadata \\ false) do

    {flags, optional_header} =
      query_flags_header(values, page_size, paging_state, serial_consistency,
        skip_metadata)

    body =
      Body.write_long_string(q) <>
      Body.write_consistency(consistency) <>
      <<flags>> <>
      optional_header

    {0x07, body}
  end

  def prepare(q), do: {0x09, Body.write_long_string(q)}

  def execute(id, consistency \\ :one, values \\ nil, page_size \\ nil,
    paging_state \\ nil, serial_consistency \\ nil, skip_metadata \\ false) do

    {flags, optional_header} =
      query_flags_header(values, page_size, paging_state, serial_consistency,
        skip_metadata)

    body =
      Body.write_short_bytes(id) <>
      Body.write_consistency(consistency) <>
      <<flags>> <>
      optional_header

    {0x0A, body}
  end

  defp query_flags_header(values, page_size, paging_state, serial_consistency,
    skip_metadata), do:
    {0x00, <<>>}
      |> add_skip_metadata(skip_metadata)
      |> add_query_values(values)
      |> add_page_size(page_size)
      |> add_paging_state(paging_state)
      |> add_serial_consistency(serial_consistency)

  # Add batch support

  # Add register support

  defp add_skip_metadata(fh, false), do: fh
  defp add_skip_metadata({flags, header}, true), do: {flags ||| 0x02, header}

  defp add_query_values(fh, vs) when is_nil(vs) or length(vs) == 0, do: fh

  defp add_query_values({flags, header}, vs) do
    with_size = header <> Body.write_short(length(vs))
    data = Enum.reduce(vs, with_size, fn(v, acc) -> acc <> Body.write_bytes(v) end)
    {flags ||| 0x01, data}
  end

  defp add_page_size(fh, nil), do: fh
  defp add_page_size({flags, header}, page_size), do:
    {flags ||| 0x04, header <> Body.write_int(page_size)}

  defp add_paging_state(fh, nil), do: fh
  defp add_paging_state({flags, header}, paging_state), do:
    {flags ||| 0x08, header <> Body.write_bytes(paging_state)}

  defp add_serial_consistency(fh, nil), do: fh
  defp add_serial_consistency({flags, header}, s_consistency), do:
    {flags ||| 0x10, header <> Body.write_consistency(s_consistency)}

end