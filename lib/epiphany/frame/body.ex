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

  def write_int(i) when is_integer(i), do:  << i :: size(32) >>

  def write_long(l) when is_integer(l), do:  << l :: size(64) >>

  def write_short(s) when is_integer(s), do: << s :: size(16) >>

  def read_int(b), do: read_number(b, 4)

  def read_long(b), do: read_number(b, 8)

  def read_short(b), do: read_number(b, 2)

  defp read_number(b, n_size) when is_binary(b) and byte_size(b) >= n_size do
    b_size = n_size * 8
    << n :: size(b_size), rest :: binary >> = b
    {:ok, n, rest}
  end

  defp read_number(b, n_size) when is_binary(b) and byte_size(b) < n_size, do:
    {:error, :too_short}

  def write_string(s) when is_binary(s), do:
    write_short(byte_size(s)) <> s

  def write_long_string(s) when is_binary(s), do:
    write_int(byte_size(s)) <> s

  def write_bytes(b) when is_binary(b), do:
    write_int(byte_size(b)) <> b

  def write_short_bytes(b) when is_binary(b), do:
    write_short(byte_size(b)) <> b

  def read_string(b), do: read_binary(&read_short/1, b)

  def read_long_string(b), do: read_binary(&read_int/1, b)

  def read_bytes(b), do: read_binary(&read_int/1, b)

  def read_short_bytes(b), do: read_binary(&read_short/1, b)

  defp read_binary(read_count, data) when is_binary(data) do
    read_count.(data)
    |> flat_map( fn(count, item_and_rest) ->
      case byte_size(item_and_rest) >= count do
        true ->
          << s :: binary-size(count), rest :: binary >> = item_and_rest
          {:ok, s, rest}
        false ->
          {:error, :too_short}
      end
    end)
  end

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
    read_short(b)
    |> flat_map(&(read_string_list(&1, [], &2)))
  end

  defp read_string_list(0, acc, data), do: {:ok, Enum.reverse(acc), data}

  defp read_string_list(_list_size, _acc, <<>>), do: {:error, :too_short}

  defp read_string_list(list_size, acc, data) do
    read_string(data)
    |> flat_map(&(read_string_list(list_size - 1, [&1|acc], &2)))
  end

  def read_string_map(b) when is_binary(b) do
    read_short(b)
    |> flat_map( &( read_string_map(&1, %{}, &2) ) )
  end

  defp read_string_map(0, acc, data), do: {:ok, acc, data}

  defp read_string_map(_map_size, _acc, << >>), do: {:error, :too_short}

  defp read_string_map(map_size, acc, data) do
    read_string(data)
    |> flat_map( fn(key, s_and_rest) ->
      read_string(s_and_rest)
      |> flat_map( &(read_string_map(map_size - 1, Map.put(acc, key, &1), &2)) )
    end)
  end

  def read_string_multimap(b) when is_binary(b) do
    read_short(b)
    |> flat_map( &(read_string_multimap(&1, %{}, &2)) )
  end

  defp read_string_multimap(0, acc, data), do: {:ok, acc, data}

  defp read_string_multimap(_map_size, _acc, <<>>), do: {:error, :too_short}

  defp read_string_multimap(map_size, acc, data) do
    read_string(data)
    |> flat_map( fn(key, s_list_and_rest) ->
      read_string_list(s_list_and_rest)
      |> flat_map( &(read_string_multimap(map_size - 1, Map.put(acc, key, &1), &2)) )
      end)
  end

  # TODO option (but may not be possible to generify)

  # TODO option list (see above)

  # TODO inet

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

  def read_consistency(b) do
    read_short(b)
    |> flat_map( fn(code, rest) ->
        {:ok, short_to_consistency(code), rest}
       end)
  end

  defp short_to_consistency(b) do
    case b do
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
  end

  defp flat_map({:ok, item, rest}, f), do: f.(item, rest)
  defp flat_map({:error, :too_short} = error, _), do: error

end