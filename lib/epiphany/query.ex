defmodule Epiphany.Query do
  @moduledoc false

  defmodule Parameters do
    defstruct consistency: :one, values: [], page_size: nil,
              paging_state: nil, serial_consistency: nil, skip_metadata: false
  end

end