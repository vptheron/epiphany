defmodule Epiphany.Connection do

  @moduledoc """
  A Connection to a Cassandra node.  Spawns an actual connection as a child.

  Can be used concurrently by several clients.  Is maintaining the match between
  streams and clients.
  """

  use GenServer

  alias Epiphany.Response
  alias Epiphany.Frame.TcpConnection
  alias Epiphany.Request

  @stream_max 32768

  def start_link({ip, port}) do
    GenServer.start_link(__MODULE__, {ip, port})
  end

  def send(conn, req = {_, _}) do
    GenServer.call(conn, {:send, req})
  end

  def close(conn) do
    GenServer.cast(conn, :close)
  end

  # Callbacks

  def init({ip, port}) do
    {:ok, connection} = TcpConnection.start_link(ip, port, self)

    streams = Enum.to_list(1..@stream_max)
    {:ok, %{conn: connection, streams: streams, clients: %{}}}
  end

  def handle_cast(:connected, s = %{conn: conn}) do
    # Handle initialization better
    {code, body} = Request.startup
    f = %Epiphany.Frame{stream: 0, op_code: code, body: body}
    TcpConnection.send(conn, f)
    {:noreply, s}
  end

  def handle_cast({:frame, frame}, %{clients: clients, streams: streams} = s) do
    {stream, dec_frame} = Response.decode(frame)
    new_clients =
      case Map.fetch(clients, stream) do
        :error -> clients
        {:ok, client} ->
          GenServer.reply(client, dec_frame)
          Map.delete(clients, client)
      end

    {:noreply, %{s| clients: new_clients, streams: [stream|streams]}}
  end

  def handle_cast(:close, state) do
      # May need to reply to pending clients with an error
      TcpConnection.close(state.conn)
      {:stop, :normal, state}
    end

  def handle_call({:send, {op_code, body}},
                  from,
                  %{clients: clients, streams: streams, conn: conn} = s) do

    [stream|new_streams] = streams  # Handle case where there is no more streams

    conn
    |> TcpConnection.send(%Epiphany.Frame{stream: stream, op_code: op_code, body: body})

    {:noreply, %{s| streams: new_streams, clients: Map.put(clients, stream, from)}}
  end

end