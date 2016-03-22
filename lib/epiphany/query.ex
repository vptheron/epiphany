defmodule Epiphany.Query do
  @moduledoc false

  defstruct statement: nil, consistency: :one, values: [], page_size: nil,
            paging_state: nil, serial_consistency: nil

end