defmodule Epiphany.DataTypesTest do
  use ExUnit.Case, async: false
  use ExCheck

  import Epiphany.DataTypes

  property "ascii support" do
    for_all b in binary, do: b == (b |> to_ascii |> from_ascii)
  end

  property "bigint support" do
    for_all bi in int do
      encoded = to_bigint(bi)
      (byte_size(encoded) == 8) && (bi == from_bigint(encoded))
    end
  end

  property "blob support" do
    for_all b in binary, do: b == (b |> to_blob |> from_blob)
  end

  test "boolean support" do
    assert to_boolean(true) == <<1>>
    assert to_boolean(false) == <<0>>
    for_all b in such_that(bb in byte when bb != 0) do
      from_boolean(<<b>>) == true
    end
    assert from_boolean(<<0>>) == false
  end

  property "double support" do
    for_all f in real do
      encoded = to_double(f)
      (byte_size(encoded) == 8) && (f == from_double(encoded))
    end
  end

  property "float support" do
    for_all f in real do
      b_f = << f :: float-size(32) >>
      << ff :: float-size(32) >> = b_f
      encoded = to_float(ff)
      (byte_size(encoded) == 4) && (ff == from_float(encoded))
    end
  end

  property "int support" do
    for_all i in int do
      b_i = << i :: integer-size(32) >>
      << ii :: integer-size(32) >> = b_i
      encoded = to_int(ii)
      (byte_size(encoded) == 4) && (ii == from_int(encoded))
    end
  end

  property "list support" do
    for_all l in list(int) do
      l == (l |> to_list(&to_bigint/1) |> from_list(&from_bigint/1))
    end
    for_all l in list(binary) do
      l == (l |> to_list(&to_text/1) |> from_list(&from_text/1))
    end
  end

  # TODO add test for map support

end