defmodule Epiphany do
  @moduledoc false

  alias Epiphany.Connection
  alias Epiphany.Request

  def new, do: new({"localhost", 9042})

  def new(a = {_ip, _port}), do: Connection.start_link(a)

  def options(c) do
    Connection.send(c, Request.options())
  end

  def query(c, q = %Epiphany.Query{}) do
    Connection.send(c, Request.query(
      q.statement,
      q.consistency,
      q.values,
      q.page_size,
      q.paging_state
    ))
  end

  def query(c, q) when is_binary(q) do
    query(c, %Epiphany.Query{statement: q})
  end

  def prepare(c, q) do
    Connection.send(c, Request.prepare(q))
  end

  def execute(c, id) do
    Connection.send(c, Request.execute(id))
  end

  def close(c), do: Connection.close(c)

end