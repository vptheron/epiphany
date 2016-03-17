defmodule Epiphany.Frame do
  @moduledoc """
  A module to manipulate frames.  Provides functions to encode a frame
  to a sequence of bytes, or read a sequence of bytes into a frame object.
  """

  defstruct version: 0x03,
            flags: 0x00,
            stream: 0,
            op_code: 0,
            body: <<>>

  alias Epiphany.Frame.Body

  def read_frame(data) when byte_size(data) < 9, do: {:error, :incomplete_header}

  def read_frame(data) do
    << version,
       flags,
       stream :: size(16),
       op_code,
       length :: size(32),
       body_and_rest :: binary >> = data

    %Epiphany.Frame{version: version, flags: flags, stream: stream, op_code: op_code}
    |> read_body(body_and_rest, length)
  end

  defp read_body(_, data, length) when byte_size(data) < length, do:
    {:error, :incomplete_body}

  defp read_body(f, data, length) do
    << body :: binary-size(length), rest :: binary >> = data
    {:ok, %Epiphany.Frame{f | body: body}, rest}
  end

  def write_frame(%Epiphany.Frame{version: version, flags: flags, body: body,
                                  stream: stream, op_code: op_code}) do
    << version, flags >> <> Body.write_short(stream) <> << op_code >> <>
    Body.write_int(byte_size(body)) <> body
  end

end