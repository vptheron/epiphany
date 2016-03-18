defmodule Epiphany.Request do
  @moduledoc """
  This module provides convenient functions to create request frames.  It
   provides functions for each type of request, and returns the operation code
   and the serialized body to be inserted in the frame object.
  """

  alias Epiphany.Frame.Body

  use Bitwise

  def startup() do
    {0x01, Body.write_string_map(%{"CQL_VERSION" => "3.0.0"})}
  end

  # Auth_response

  def options() do
    {0x05, <<>>}
  end

  def query(q, consistency \\ :one,
    values \\ nil, page_size \\ nil, paging_state \\ nil) do
    {flags, optional_header} =
      {0x02, <<>>}                # Set to skip metadata for now
      |> add_query_values(values)
      |> add_page_size(page_size)
      |> add_paging_state(paging_state)

    # Add real support for parameters
    body =
      Body.write_long_string(q) <>
      Body.write_consistency(consistency) <>
      <<flags>> <>
      optional_header

    {0x07, body}
  end

  defp add_query_values(fh, vs) when is_nil(vs) or length(vs) == 0, do: fh

  defp add_query_values({flags, header}, vs) do
    with_size = header <> Body.write_short(length(vs))
    data = Enum.reduce(vs, with_size, fn(v, acc) -> acc <> Body.write_bytes(v) end)
    {flags ||| 0x01, data}
  end

  defp add_page_size(fh, nil), do: fh
  defp add_page_size({flags, header}, page_size) do
    {flags ||| 0x04, header <> Body.write_int(page_size)}
  end

  defp add_paging_state(fh, nil), do: fh
  defp add_paging_state({flags, header}, paging_state) do
    {flags ||| 0x08, header <> Body.write_bytes(paging_state)}
  end

  def prepare(q) do
    {0x09, Body.write_long_string(q)}
  end

  def execute(id, consistency \\ :one,
    _values \\ nil, _page_size \\ nil, _paging_state \\ nil) do
    # Share code with query
    flags =
      0x02   # No metadata for now
     # |> update_flags(values, 0x01)
     # |> update_flags(page_size, 0x04)
     # |> update_flags(paging_state, 0x08)

    body =
      Body.write_short_bytes(id) <>
      Body.write_consistency(consistency) <>
      <<flags>>

    {0x0A, body}
  end

  # Add batch support

  # Add register support

  defp update_flags(flags, nil, _), do: flags
  defp update_flags(flags, _, b), do: flags ||| b
end