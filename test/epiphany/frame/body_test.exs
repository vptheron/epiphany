defmodule Epiphany.Frame.BodyTest do
  use ExUnit.Case

  alias Epiphany.Frame.Body

  test "Int support" do
    encoded = Body.write_int(42)
    assert byte_size(encoded) == 4
    {:ok, dec, <<>>} = Body.read_int(encoded)
    assert dec == 42
  end

  test "Long support" do
    encoded = Body.write_long(42)
    assert byte_size(encoded) == 8
    {:ok, dec, <<>>} = Body.read_long(encoded)
    assert dec == 42
  end

  test "Short support" do
    encoded = Body.write_short(42)
    assert byte_size(encoded) == 2
    {:ok, dec, <<>>} = Body.read_short(encoded)
    assert dec == 42
  end
  
end