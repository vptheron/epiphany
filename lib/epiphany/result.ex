defmodule Epiphany.Result do
  @moduledoc false

  defstruct rows: [], row_count: 0, paging_state: nil
  # consider storing the originating query to be able to call `next_page` easily

  def has_more?(%Epiphany.Result{paging_state: ps}), do: !is_nil ps

  defmodule Row do

    defstruct columns: [], col_count: 0

    alias Epiphany.DataTypes, as: DT

    def as_ascii(r = %Row{}, i), do: as_type(r, &DT.from_ascii/1, i)

    def as_bigint(r = %Row{}, i), do: as_type(r, &DT.from_bigint/1, i)

    def as_blob(r = %Row{}, i), do: as_type(r, &DT.from_blob/1, i)

    def as_boolean(r = %Row{}, i), do: as_type(r, &DT.from_boolean/1, i)

    # Decimal

    def as_double(r = %Row{}, i), do: as_type(r, &DT.from_double/1, i)

    def as_float(r = %Row{}, i), do: as_type(r, &DT.from_float/1, i)

    # Inet

    def as_int(r = %Row{}, i), do: as_type(r, &DT.from_int/1, i)

    def as_list(r = %Row{}, i, f), do: as_type(r, &(DT.from_list(&1,f)), i)

    def as_map(r = %Row{}, i, kf, vf), do:
      as_type(r, &(DT.from_map(&1, kf, vf)), i)

    def as_set(r = %Row{}, i, f), do: as_type(r, &(DT.from_set(&1,f)), i)

    def as_text(r = %Row{}, i), do: as_type(r, &DT.from_text/1, i)

    def as_timestamp(r = %Row{}, i), do: as_type(r, &DT.from_timestamp/1, i)

      # UUID

    def as_varchar(r = %Row{}, i), do: as_varchar(r,i)

      # Varint

      # Timeuuid

    def as_tuple(r = %Row{}, i, fs), do: as_type(r, &(DT.from_tuple(&1,fs)), i)

    defp as_type(%Row{col_count: count}, _, i) when i >= count, do:
      {:error, "Given index (#{i}) is out of bound, only #{count} columns"}

    defp as_type(%Row{columns: col}, f, i), do: f.(Enum.at(col, i))

  end

end