defmodule Epiphany.Frame.BodyTest do
  use ExUnit.Case, async: false
  use ExCheck

  import Epiphany.Frame.Body, only: :functions

  property "Int encode / decode" do
    for_all x in int, do: {:ok, x, <<>>} == (x |> write_int |> read_int)
  end

  property "Int too short" do
    for_all x in int do
      encoded = write_int(x)
      truncated = :erlang.binary_part(encoded, 0, byte_size(encoded) - 1)
      {:error, :too_short} == read_int(truncated)
    end
  end

  property "Int plus rest" do
    for_all x in int, do: {:ok, x, <<3>>} == (x |> write_int |> add_rest |> read_int)
  end

  property "Long encode / decode" do
    for_all x in int, do: {:ok, x, <<>>} == (x |> write_long |> read_long)
  end

  property "Long too short" do
    for_all x in int do
      encoded = write_long(x)
      truncated = :erlang.binary_part(encoded, 0, byte_size(encoded) - 1)
      {:error, :too_short} == read_long(truncated)
    end
  end

  property "Long plus rest" do
    for_all x in int, do: {:ok, x, <<3>>} == (x |> write_long |> add_rest |> read_long)
  end

  property "Short encode / decode" do
    for_all x in non_neg_integer, do:
      {:ok, x, <<>>} == (x |> write_short |> read_short)
  end

  property "Short too short" do
    for_all x in non_neg_integer do
      encoded = write_short(x)
      truncated = :erlang.binary_part(encoded, 0, byte_size(encoded) - 1)
      {:error, :too_short} == read_short(truncated)
    end
  end

  property "Short plus rest" do
    for_all x in non_neg_integer, do:
      {:ok, x, <<3>>} == (x |> write_short |> add_rest |> read_short)
  end

  property "String encode / decode" do
    for_all s in binary, do: {:ok, s, <<>>} == (s |> write_string |> read_string)
  end

  property "String too short" do
    for_all s in binary do
      encoded = write_string(s)
      truncated = :erlang.binary_part(encoded, 0, byte_size(encoded) - 1)
      {:error, :too_short} == read_string(truncated)
    end
  end

  property "String plus rest" do
    for_all s in binary, do:
      {:ok, s, <<3>>} == (s |> write_string |> add_rest |> read_string)
  end

  property "Long string encode / decode" do
    for_all s in binary, do:
      {:ok, s, <<>>} == (s |> write_long_string |> read_long_string)
  end

  property "Long string too short" do
    for_all s in binary do
      encoded = write_long_string(s)
      truncated = :erlang.binary_part(encoded, 0, byte_size(encoded) - 1)
      {:error, :too_short} == read_long_string(truncated)
    end
  end

  property "Long string plus rest" do
    for_all s in binary, do:
      {:ok, s, <<3>>} == (s |> write_long_string |> add_rest |> read_long_string)
  end

  property "Bytes encode / decode" do
    for_all s in binary, do: {:ok, s, <<>>} == (s |> write_bytes |> read_bytes)
  end

  test "nil bytes encode / decode" do
    assert {:ok, nil, <<>>} == (nil |> write_bytes |> read_bytes)
  end

  property "Bytes too short" do
    for_all s in binary do
      encoded = write_bytes(s)
      truncated = :erlang.binary_part(encoded, 0, byte_size(encoded) - 1)
      {:error, :too_short} == read_bytes(truncated)
    end
  end

  property "Bytes plus rest" do
    for_all s in binary, do:
      {:ok, s, <<3>>} == (s |> write_bytes |> add_rest |> read_bytes)
  end

  property "Short bytes encode / decode" do
    for_all s in binary, do: {:ok, s, <<>>} ==
      (s |> write_short_bytes |> read_short_bytes)
  end

  property "Short bytes too short" do
    for_all s in binary do
      encoded = write_short_bytes(s)
      truncated = :erlang.binary_part(encoded, 0, byte_size(encoded) - 1)
      {:error, :too_short} == read_short_bytes(truncated)
    end
  end

  property "Short bytes plus rest" do
    for_all s in binary, do:
      {:ok, s, <<3>>} == (s |> write_short_bytes |> add_rest |> read_short_bytes)
  end

  property "String list encode / decode" do
    for_all l in list(binary), do:
      {:ok, l, <<>>} == (l |> write_string_list |> read_string_list)
  end

  property "String list too short" do
    for_all l in list(binary) do
      encoded = write_string_list(l)
      truncated = :erlang.binary_part(encoded, 0, byte_size(encoded) - 1)
      {:error, :too_short} == read_string_list(truncated)
    end
  end

  property "String list plus rest" do
    for_all l in list(binary), do:
      {:ok, l, <<3>>} == (l |> write_string_list |> add_rest |> read_string_list)
  end

 # TODO string_map

 # TODO string_multimap

  property "Consistency encode / decode" do
    for_all c in oneof([:any, :one, :two, :three, :quorum, :all, :local_quorum,
      :serial, :local_serial, :local_one]) do
      {:ok, c, <<>>} == (c |> write_consistency |> read_consistency)
    end
  end

  property "Consistency too short" do
    for_all c in oneof([:any, :one, :two, :three, :quorum, :all, :local_quorum,
     :serial, :local_serial, :local_one]) do
     encoded = write_consistency(c)
     truncated = :erlang.binary_part(encoded, 0, byte_size(encoded) - 1)
     {:error, :too_short} == read_consistency(truncated)
    end
  end

  property "Consistency plus rest" do
    for_all c in oneof([:any, :one, :two, :three, :quorum, :all, :local_quorum,
      :serial, :local_serial, :local_one]) do
      {:ok, c, <<3>>} == (c |> write_consistency |> add_rest |> read_consistency)
    end
  end

  defp add_rest(b), do: b <> <<3>>

end