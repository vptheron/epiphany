defmodule Epiphany.Frame.Body do
  @moduledoc """
  This module contains utility functions to read/write
  body elements for frames.

  All the `write` functions return a sequence of bytes, even when the
  representation of the entity is a single byte.

  All the `read` functions returns the tuple {:ok, result, rest} where
  result is the decoded entity, and rest is the rest of the byte string
  after decoding the entity.  {:error, too_short} may be returned if the
  given byte string was not complete or long enough to be decoded as a valid
  entity.
  """

  def write_int(i) when is_integer(i), do:  << i :: signed-integer-size(32) >>

  def write_long(l) when is_integer(l), do:  << l :: signed-integer-size(64) >>

  def write_short(s) when is_integer(s), do: << s :: unsigned-integer-size(16) >>

  def read_int(b), do: read_number(b, 4)

  def read_long(b), do: read_number(b, 8)

  def read_short(b) when is_binary(b) and byte_size(b) >= 2 do
    << n :: unsigned-integer-size(16), rest :: binary >> = b
    {:ok, n, rest}
  end

  def read_short(b) when is_binary(b) and byte_size(b) < 2, do:
    {:error, :too_short}

  defp read_number(b, n_size) when is_binary(b) and byte_size(b) >= n_size do
    b_size = n_size * 8
    << n :: signed-integer-size(b_size), rest :: binary >> = b
    {:ok, n, rest}
  end

  defp read_number(b, n_size) when is_binary(b) and byte_size(b) < n_size, do:
    {:error, :too_short}

  def write_string(s) when is_binary(s), do:
    write_short(byte_size(s)) <> s

  def write_long_string(s) when is_binary(s), do:
    write_int(byte_size(s)) <> s

  def write_bytes(nil), do: <<255,255,255,255>>
  def write_bytes(b) when is_binary(b), do:
    write_int(byte_size(b)) <> b

  def write_short_bytes(b) when is_binary(b), do:
    write_short(byte_size(b)) <> b

  def read_string(b), do: read_binary(&read_short/1, b)

  def read_long_string(b), do: read_binary(&read_int/1, b)

  def read_bytes(<< 255,255,255,255 , rest :: binary >>), do: {:ok, nil, rest}

  def read_bytes(<< length :: size(32), s_rest :: binary >>)
    when byte_size(s_rest) >= length do
    << b :: binary-size(length), rest :: binary >> = s_rest
    {:ok, b, rest}
  end

  def read_bytes(<<length :: size(32), rest :: binary>>)
    when byte_size(rest) < length, do:
      {:error, :too_short}
  def read_bytes(b) when byte_size(b) < 4, do: {:error, :too_short}

  def read_short_bytes(b), do: read_binary(&read_short/1, b)

  defp read_binary(count_reader, data) when is_binary(data) do
    with {:ok, c, rest} <- count_reader.(data),
    do: read_binary_with_count(c, rest)
  end

  defp read_binary_with_count(count, data) when byte_size(data) >= count do
    << s :: binary-size(count), rest :: binary >> = data
    {:ok, s, rest}
  end
  defp read_binary_with_count(count, data) when byte_size(data) < count, do:
    {:error, :too_short}

    # TODO uuid

  def write_string_list(l) when is_list(l), do:
    write_collection(l, &(&2 <> write_string(&1)))

  def write_string_map(m) when is_map(m) do
    write_collection(m, fn({k,v}, acc) ->
      acc <> write_string(k) <> write_string(v)
    end)
  end

  def write_string_multimap(m) when is_map(m) do
    write_collection(m, fn({k,v}, acc) ->
      acc <> write_string(k) <> write_string_list(v)
    end)
  end

  defp write_collection(col, f), do:
    write_short(Enum.count(col)) <> Enum.reduce(col, << >>, f)

  def read_string_list(b) when is_binary(b) do
    with {:ok, length, rest} <- read_short(b),
    do: read_string_list(length, [], rest)
  end

  defp read_string_list(0, acc, data), do: {:ok, Enum.reverse(acc), data}

  defp read_string_list(_list_size, _acc, <<>>), do: {:error, :too_short}

  defp read_string_list(list_size, acc, data) do
    with {:ok, s, rest} <- read_string(data),
    do: read_string_list(list_size - 1, [s|acc], rest)
  end

  def read_string_map(b) when is_binary(b) do
    with {:ok, s, rest} <- read_short(b),
    do: read_string_map(s, %{}, rest)
  end

  defp read_string_map(0, acc, data), do: {:ok, acc, data}

  defp read_string_map(_map_size, _acc, << >>), do: {:error, :too_short}

  defp read_string_map(map_size, acc, data) do
   with {:ok, k, rest} <- read_string(data),
        {:ok, v, rest} <- read_string(rest),
   do: read_string_map(map_size - 1, Map.put(acc, k, v), rest)
  end

  def read_string_multimap(b) when is_binary(b) do
    with {:ok, s, rest} <- read_short(b),
    do: read_string_multimap(s, %{}, rest)
  end

  defp read_string_multimap(0, acc, data), do: {:ok, acc, data}

  defp read_string_multimap(_map_size, _acc, <<>>), do: {:error, :too_short}

  defp read_string_multimap(map_size, acc, data) do
    with {:ok, k, rest} <- read_string(data),
         {:ok, l, rest} <- read_string_list(rest),
    do: read_string_multimap(map_size - 1, Map.put(acc, k, l), rest)
  end

  # TODO option (but may not be possible to generify)

  # TODO option list (see above)

  def write_inet({address,port}),
  do: << byte_size(address) :: size(8) >> <> address <> write_int(port)

  def read_inet(<< s, add_port :: binary >>) when byte_size(add_port) < s,
  do: {:error, :too_short}

  def read_inet(<<s, add_port :: binary>>) do
    with << address :: binary-size(s), rest :: binary >> <- add_port,
         {:ok, port, rest} <- read_int(rest),
    do: {:ok, {address, port}, rest}
  end

  def write_consistency(c) do
    case c do
      :any -> write_short(0x0000)
      :one -> write_short(0x0001)
      :two -> write_short(0x0002)
      :three -> write_short(0x0003)
      :quorum -> write_short(0x0004)
      :all -> write_short(0x0005)
      :local_quorum -> write_short(0x0006)
      :each_quorum -> write_short(0x0007)
      :serial -> write_short(0x0008)
      :local_serial -> write_short(0x0009)
      :local_one -> write_short(0x000A)
    end
  end

  def read_consistency(b) when byte_size(b) < 2, do: {:error, :too_short}
  def read_consistency(<< s :: unsigned-integer-size(16), rest :: binary >>) do
    c = case s do
      0x0000 -> :any
      0x0001 -> :one
      0x0002 -> :two
      0x0003 -> :three
      0x0004 -> :quorum
      0x0005 -> :all
      0x0006 -> :local_quorum
      0x0007 -> :each_quorum
      0x0008 -> :serial
      0x0009 -> :local_serial
      0x000A -> :local_one
    end
    {:ok, c, rest}
  end

end