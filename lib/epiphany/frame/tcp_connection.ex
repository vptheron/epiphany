defmodule Epiphany.Frame.TcpConnection do
  @moduledoc """
  A direct connection to a Cassandra node.  TcpConnection opens a TCP connection,
  sends bytes to the node and forwards received frames to its client.

  The client is given at creation time and will always be the recipient of
  incoming frames.
  """
  require Logger
  use Connection

  alias Epiphany.Frame

  def start_link(host, port, client, timeout \\ 5000) do
    Connection.start_link(
      __MODULE__,
      {host, port, timeout, client})
  end

  def send(conn, frame = %Epiphany.Frame{}), do:
    Connection.call(conn, {:send, frame})

  def close(conn), do: Connection.call(conn, :close)

  # Callbacks

  def init({host, port, timeout, client}) do
    s = %{host: to_char_list(host), port: port, timeout: timeout,
          sock: nil, client: client, buffer: <<>>}
    {:connect, :init, s}
  end

  def connect(_info, %{sock: nil, host: host, port: port,
    timeout: timeout, client: client} = s) do
    case :gen_tcp.connect(host, port, [:binary, active: true], timeout) do
        {:ok, sock} ->
          Logger.debug "Connected to #{host}:#{port}"
          GenServer.cast(client, :connected)
          {:ok, %{s | sock: sock}}
        {:error, _} ->
          Logger.warn "Failed to connect to #{host}:#{port}"
          {:backoff, 2000, s}  # Make this configurable?
    end
  end

  def disconnect(info, %{sock: sock} = s) do
    :ok = :gen_tcp.close(sock)
    case info do
      {:close, from} ->
        Connection.reply(from, :ok)
        {:stop, :normal, s}
      {:error, reason} ->
        Logger.warn "Disconnecting: #{reason}"
        {:connect, :reconnect, %{s | sock: nil}}
    end
  end

  def handle_call(_, _, %{sock: nil} = s) do
    {:reply, {:error, :disconnected}, s}
  end

  def handle_call({:send, frame}, _, %{sock: sock} = s) do
    case :gen_tcp.send(sock, Frame.write_frame(frame)) do
      :ok -> {:reply, :ok, s}
      {:error, _} = error ->  {:disconnect, error, error, s}
    end
  end

  def handle_call(:close, from, s) do
    {:disconnect, {:close, from}, s}
  end

  def handle_info({:tcp, _, msg}, %{buffer: buffer} = s) do
    read_frame(%{s | buffer: buffer <> msg})
  end

  def handle_info({:tcp_closed, _}, s) do
    {:disconnect, {:error, :closed}, s}
  end

  defp read_frame(%{client: client, buffer: buffer} = s) do
    case Frame.read_frame(buffer) do
      {:error, _} -> {:noreply, s}
      {:ok, frame, rest} ->
        GenServer.cast(client, {:frame, frame})
        read_frame(%{s | buffer: rest})
    end
  end

end