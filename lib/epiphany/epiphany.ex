defmodule Epiphany do
  @moduledoc false

  alias Epiphany.Connection
  alias Epiphany.Request

  def new, do: new({"localhost", 9042})

  def new(a = {_ip, _port}), do: Connection.start_link(a)

  def options(c) do
    Connection.send(c, Request.options())
  end

  def query(c, q) do
    Connection.send(c, Request.query(q))
  end

  def prepare(c, q) do
    Connection.send(c, Request.prepare(q))
  end

  def execute(c, id) do
    Connection.send(c, Request.execute(id))
  end

  def close(c), do: Connection.close(c)

end