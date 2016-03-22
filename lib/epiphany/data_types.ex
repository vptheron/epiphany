defmodule Epiphany.DataTypes do
  @moduledoc false

  alias Epiphany.Frame.Body

  def to_ascii(d) when is_binary(d), do: d

  def from_ascii(b) when is_binary(b), do: b

  def to_bigint(i) when is_integer(i), do: <<i :: signed-integer-size(64) >>

  def from_bigint(b) when is_binary(b) do
    << bi :: signed-integer-size(64) >> = b
    bi
  end

  def to_blob(b) when is_binary(b), do: b

  def from_blob(b) when is_binary(b), do: b

  def to_boolean(true), do: <<1>>
  def to_boolean(false), do: <<0>>

  def from_boolean(<< b >>), do: b != 0

  # decimal

  def to_double(d) when is_number(d), do: <<d :: float-size(64) >>

  def from_double(b) when is_binary(b) do
    << d :: float-size(64) >> = b
    d
  end

  def to_float(f) when is_number(f), do: <<f :: float-size(32) >>

  def from_float(b) when is_binary(b) do
    << f :: float-size(32) >> = b
    f
  end

  # inet

  def to_int(i) when is_integer(i), do: <<i :: integer-size(32) >>

  def from_int(b) when is_binary(b) do
    << i :: integer-size(32) >> = b
    i
  end

  def to_list(l, f) when is_list(l) do
    all_bytes = l |> Enum.reduce(<<>>, &( &2 <> Body.write_bytes(f.(&1)) ))
    Body.write_int(Enum.count(l)) <> all_bytes
  end

  def from_list(b, f) when is_binary(b) do
    {:ok, size, list_bs} = Body.read_int(b)
    if size == 0 do
      []
    else
      {l, _} = (1..size) |> Enum.reduce({[], list_bs}, fn(_, {items, bs}) ->
                 {:ok, item_bs, after_item} = Body.read_bytes(bs)
                 {[f.(item_bs)|items], after_item}
               end)
      Enum.reverse(l)
    end
  end

  def to_map(m, kf, vf) when is_map(m) do
    all_bytes = m |> Enum.reduce(<<>>, fn({k,v}, acc) ->
      acc <> Body.write_bytes(kf.(k)) <> Body.write_bytes(vf.(v))
    end)
    Body.write_int(Enum.count(m)) <> all_bytes
  end

  def from_map(b, kf, vf) when is_binary(b) do
    {:ok, size, map_bs} = Body.read_int(b)
    if size == 0 do
      %{}
    else
      {m, _} = (1..size) |> Enum.reduce({%{}, map_bs}, fn(_, {items, bs}) ->
                 {:ok, key_bs, after_key} = Body.read_bytes(bs)
                 {:ok, value_bs, after_value} = Body.read_bytes(after_key)
                 {Map.put(items, kf.(key_bs), vf.(value_bs)), after_value}
               end)
      m
    end
  end

  def to_set(s = %MapSet{}, f) do
    all_bytes = s |> Enum.reduce(<<>>, &(&2 <> Body.write_bytes(f.(&1)) ))
    Body.write_int(MapSet.size(s)) <> all_bytes
  end

  def from_set(b, f) do
    {:ok, size, set_bs} = Body.read_int(b)
    if size == 0 do
        MapSet.new
    else
      {s, _} = (1..size) |> Enum.reduce({MapSet.new, set_bs}, fn(_, {items, bs}) ->
                 {:ok, item_bs, after_item} = Body.read_bytes(bs)
                 {MapSet.put(items, f.(item_bs)), after_item}
               end)
      s
    end
  end

  def to_text(t) when is_binary(t), do: t

  def from_text(b) when is_binary(b), do: b

  def to_timestamp(ts) when is_integer(ts), do: to_bigint(ts)
  # May need to support a tuple form here

  def from_timestamp(b) when is_binary(b), do: from_bigint(b)

  # UUID

  def to_varchar(v), do: to_text(v)

  def from_varchar(b), do: from_text(b)

  # Varint

  # timeuuid

  def to_tuple(t, fs) when is_tuple(t), do:
    to_tuple(:erlang.tuple_to_list(t), fs)

  def to_tuple(ts, fs) when is_list(ts) do
    List.zip([ts, fs])
    |> Enum.reduce(<<>>, fn({t,f}, acc) ->
      acc <> Body.write_bytes(f.(t))
    end)
  end

  def from_tuple(b, fs) when is_binary(b) do
    l = Enum.reduce(fs, {[], b}, fn(f, {items, t_bs}) ->
          {:ok, bs, rest} = Body.read_bytes(t_bs)
          {[f.(bs)|items], rest}
        end)
    l
    |> Enum.reverse
    |> :erlang.list_to_tuple
  end

end