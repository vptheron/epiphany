defmodule Epiphany do
  @moduledoc false

  alias Epiphany.Connection
  alias Epiphany.Request

  def new, do: new({"localhost", 9042})

  def new(a = {_ip, _port}), do: Connection.start_link(a)

  def options(c) do
    Connection.send(c, Request.options())
  end

  def query(c, q, params = %Epiphany.Query.Parameters{}) do
    Connection.send(c, Request.query(
      q,
      params.consistency,
      params.values,
      params.page_size,
      params.paging_state,
      params.serial_consistency
    ))
  end

  def query(c, q, vals) when is_list(vals) do
    query(c, q, %Epiphany.Query.Parameters{values: vals})
  end

  def query(c, q) when is_binary(q) do
    query(c, q, %Epiphany.Query.Parameters{})
  end

  def prepare(c, q) do
    Connection.send(c, Request.prepare(q))
  end

  def execute(c, id, params = %Epiphany.Query.Parameters{}) do
     Connection.send(c, Request.execute(
       id,
       params.consistency,
       params.values,
       params.page_size,
       params.paging_state,
       params.serial_consistency
     ))
   end

  def execute(c, id, vals) when is_list(vals) do
    execute(c, id, %Epiphany.Query.Parameters{values: vals})
  end

  def execute(c, id) do
    execute(c, id, %Epiphany.Query.Parameters{})
  end

  def close(c), do: Connection.close(c)

end