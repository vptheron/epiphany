defmodule Epiphany.Result do
  @moduledoc false

  defstruct rows: [], row_count: 0, paging_state: nil
  # consider storing the originating query to be able to call `next_page` easily

  def has_more?(%Epiphany.Result{paging_state: ps}), do: !is_nil ps

  defmodule Row do

    defstruct columns: [], col_count: 0, names: nil

    alias Epiphany.DataTypes, as: DT

    def as_ascii(r = %Row{}, i) when is_integer(i), do:
      as_type(r, &DT.from_ascii/1, i)

    def as_ascii(r = %Row{}, s) when is_binary(s), do:
      as_type(r, &DT.from_ascii/1, s)

    def as_bigint(r = %Row{}, i) when is_integer(i), do:
      as_type(r, &DT.from_bigint/1, i)

    def as_bigint(r = %Row{}, s) when is_binary(s), do:
      as_type(r, &DT.from_bigint/1, s)

    def as_blob(r = %Row{}, i) when is_integer(i), do:
      as_type(r, &DT.from_blob/1, i)

    def as_blob(r = %Row{}, s) when is_binary(s), do:
      as_type(r, &DT.from_blob/1, s)

    def as_boolean(r = %Row{}, i) when is_integer(i), do:
      as_type(r, &DT.from_boolean/1, i)

    def as_boolean(r = %Row{}, s) when is_binary(s), do:
       as_type(r, &DT.from_boolean/1, s)

    # Decimal

    def as_double(r = %Row{}, i) when is_integer(i), do:
      as_type(r, &DT.from_double/1, i)

    def as_double(r = %Row{}, s) when is_binary(s), do:
      as_type(r, &DT.from_double/1, s)

    def as_float(r = %Row{}, i) when is_integer(i), do:
      as_type(r, &DT.from_float/1, i)

    def as_float(r = %Row{}, s) when is_binary(s), do:
      as_type(r, &DT.from_float/1, s)

    # Inet

    def as_int(r = %Row{}, i) when is_integer(i), do:
      as_type(r, &DT.from_int/1, i)

    def as_int(r = %Row{}, s) when is_binary(s), do:
      as_type(r, &DT.from_int/1, s)

    # TODO add support once we know how to read options for these types

    def as_list(r = %Row{}, i, f) when is_integer(i), do:
      as_type(r, &(DT.from_list(&1,f)), i)

    def as_map(r = %Row{}, i, kf, vf) when is_integer(i), do:
      as_type(r, &(DT.from_map(&1, kf, vf)), i)

    def as_set(r = %Row{}, i, f) when is_integer(i), do:
      as_type(r, &(DT.from_set(&1,f)), i)

    def as_text(r = %Row{}, i) when is_integer(i), do:
      as_type(r, &DT.from_text/1, i)

    def as_text(r = %Row{}, s) when is_binary(s), do:
      as_type(r, &DT.from_text/1, s)

    def as_timestamp(r = %Row{}, i) when is_integer(i), do:
      as_type(r, &DT.from_timestamp/1, i)

    def as_timestamp(r = %Row{}, s) when is_binary(s), do:
      as_type(r, &DT.from_timestamp/1, s)

      # UUID

    def as_varchar(r = %Row{}, i) when is_integer(i), do: as_text(r,i)

      # Varint

      # Timeuuid

    def as_tuple(r = %Row{}, i, fs) when is_integer(i), do:
      as_type(r, &(DT.from_tuple(&1,fs)), i)

    defp as_type(%Row{names: nil}, _, s) when is_binary(s), do:
      {:error, "Metadata were not loaded, cannot access columns per name"}

    defp as_type(r = %Row{names: names}, f, s) when is_binary(s) do
      case Enum.find_index(names, &(&1 == s)) do
        nil -> {:error, "Given name (#{s}) does not exist"}
        i -> as_type(r, f, i)
      end
    end

    defp as_type(%Row{col_count: count}, _, i)
      when is_integer(i) and i >= count, do:
      {:error, "Given index (#{i}) is out of bound, only #{count} columns"}

    defp as_type(%Row{columns: col}, f, i)
      when is_integer(i), do: f.(Enum.at(col, i))

  end

end