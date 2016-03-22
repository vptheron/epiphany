defmodule Epiphany.FrameTest do
  use ExUnit.Case, async: false
  use ExCheck

  import Epiphany.Frame

  property "Cannot read when header is missing" do
    for_all b in binary(8), do:
      read_frame(b) == {:error, :incomplete_header}
  end

  property "Write / Read Frame" do
    for_all {v, f, body, stream, code} in {
      oneof([0x03, 0x83]),
      oneof([0x00, 0x01, 0x02]),
      binary,
      non_neg_integer,
      int(0,16)
    } do
      frame = %Epiphany.Frame{version: v, flags: f, body: body, stream: stream,
        op_code: code}
      {:ok, frame, <<>>} == (frame |> write_frame |> read_frame)
    end
  end

  property "Cannot read when body is incomplete" do
    for_all {v, f, body, stream, code} in {
      oneof([0x03, 0x83]),
      oneof([0x00, 0x01, 0x02]),
      such_that(bb in binary when byte_size(bb) > 0),
      non_neg_integer,
      int(0,16)
    } do
      frame = %Epiphany.Frame{version: v, flags: f, body: body, stream: stream,
      op_code: code}
      encoded = write_frame(frame)
      truncated = :erlang.binary_part(encoded, 0, byte_size(encoded) - 1)
      {:error, :incomplete_body} == read_frame(truncated)
    end
  end

  property "Frame with rest" do
    for_all {v, f, body, stream, code} in {
      oneof([0x03, 0x83]),
      oneof([0x00, 0x01, 0x02]),
      binary,
      non_neg_integer,
      int(0,16)
    } do
      frame = %Epiphany.Frame{version: v, flags: f, body: body, stream: stream,
      op_code: code}
      encoded = write_frame(frame) <> <<1,2,3>>
      {:ok, frame, <<1,2,3>>} == read_frame(encoded)
    end
  end

end