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
    _values \\ nil, _page_size \\ nil, _paging_state \\ nil) do
    flags =
      0x00
      #|> update_flags(values, 0x01)
      #|> update_flags(page_size, 0x04)
      #|> update_flags(paging_state, 0x08)
      |> update_flags(true, 0x02)  # No metadata for now

    # Add real support for parameters
    body =
      Body.write_long_string(q) <>
      Body.write_consistency(consistency) <>
      <<flags>>

    {0x07, body}
  end

  def prepare(q) do
    {0x09, Body.write_long_string(q)}
  end

  def execute(id, consistency \\ :one,
    _values \\ nil, _page_size \\ nil, _paging_state \\ nil) do
    # Share code with query
    flags =
      0x00
     # |> update_flags(values, 0x01)
     # |> update_flags(page_size, 0x04)
     # |> update_flags(paging_state, 0x08)
       |> update_flags(true, 0x02)  # No metadata for now

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