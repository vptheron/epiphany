defmodule Epiphany.Frame.TcpConnection do
  @moduledoc """
  A direct connection to a Cassandra node.  TcpConnection opens a TCP connection,
  sends bytes to the node and forwards received frames to its client.

  The client is given at creation time and will always be the recipient of
  incoming frames.
  """

  use Connection

  alias Epiphany.Frame

  def start_link(host, port, client, opts \\ [], timeout \\ 5000) do
    Connection.start_link(
      __MODULE__,
      {host, port, opts, timeout, client})
  end

  def send(conn, frame = %Epiphany.Frame{}), do:
    Connection.cast(conn, {:send, frame})  # investigate if call is better here

  def close(conn), do: Connection.call(conn, :close)

  # Callbacks

  def init({host, port, opts, timeout, client}) do
    s = %{host: to_char_list(host), port: port, opts: opts, timeout: timeout,
          sock: nil, client: client, buffer: <<>>}
    {:connect, :init, s}
  end

  def connect(_, %{sock: nil, host: host, port: port, opts: opts,
    timeout: timeout, client: client} = s) do
    case :gen_tcp.connect(host, port,
      [:binary, active: true] ++ opts, timeout) do
        {:ok, sock} ->
          GenServer.cast(client, :connected)
          {:ok, %{s | sock: sock}}
        {:error, _} -> {:backoff, 1000, s}
    end
  end

  def disconnect(info, %{sock: sock} = s) do
    :ok = :gen_tcp.close(sock)
    case info do
      {:close, from} ->
        Connection.reply(from, :ok)
      {:error, :closed} ->
        :error_logger.format("Connection closed~n", [])
      {:error, reason} ->
        reason = :inet.format_error(reason)
        :error_logger.format("Connection error: ~s~n", [reason])
    end
    {:connect, :reconnect, %{s | sock: nil}}
  end

  def handle_cast(_, %{sock: nil} = s) do
    {:reply, {:error, :closed}, s}
  end

  def handle_cast({:send, frame}, %{sock: sock} = s) do
    case :gen_tcp.send(sock, Frame.write_frame(frame)) do
      :ok -> {:noreply, s}
      {:error, _} = error ->{:disconnect, error, error, s}
    end
  end

  def handle_call(:close, from, s) do
    {:disconnect, {:close, from}, s}
  end

  def handle_info({:tcp, _, msg}, %{buffer: buffer} = s) do
    read_frame(%{s | buffer: buffer <> msg})
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