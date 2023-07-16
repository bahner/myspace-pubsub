defmodule ExIpfsPubsub.Topic do
  @moduledoc false

  use GenServer, restart: :transient

  require Logger
  alias ExIpfs.Multibase
  alias ExIpfsPubsub.Message
  alias ExIpfsPubsub.Subscribers
  alias ExIpfsPubsub.Websocket

  @api_url Application.compile_env(:ex_ipfs_pubsub, :api_url, "ws://127.0.0.1:5002/topic")
  @registry :ex_ipfs_pubsub_registry

  @enforce_keys [:base64url_topic, :handler, :subscribers, :topic]
  defstruct base64url_topic: nil, handler: nil, subscribers: MapSet.new(), topic: nil, ws: nil

  @type t :: %__MODULE__{
          base64url_topic: binary | nil,
          handler: pid | nil,
          subscribers: MapSet.t(pid),
          topic: binary,
          ws: ExIpfsPubsub.Websocket.t | nil
        }

  @spec new!(binary, pid) :: t()
  def new!(topic, subscriber) when is_pid(subscriber) do
    %__MODULE__{
      base64url_topic: Multibase.encode!(topic, b: "base64url"),
      handler: nil,
      subscribers: MapSet.new([subscriber]),
      topic: topic,
      ws: nil
    }
  end

  @spec start_link(t) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(topic) when is_struct(topic) do
    Logger.debug("Starting topic handler for #{topic.topic}")

    name = via_tuple(topic.topic)

    GenServer.start_link(
      __MODULE__,
      topic,
      name: name
    )
  end

  @spec init(t()) :: {:ok, t()}
  def init(topic) when is_struct(topic) do
    Logger.debug("Initializing topic handler for #{topic.topic}")

    # Set myself as handler
    state = %__MODULE__{topic | handler: self()}

    # Update subscribers registry.
    Subscribers.add_topic(state.topic, state.subscribers)

    url = URI.parse("#{@api_url}/#{topic.base64url_topic}")

    ws = Websocket.new!(url)
    state = %__MODULE__{state | ws: ws}

    {:ok, state}
  end

  @spec is_subscribed?(pid, binary) :: boolean
  def is_subscribed?(subscriber, topic) when is_pid(subscriber),
    do:
      topic
      |> via_tuple()
      |> GenServer.call({:is_subscribed, subscriber})

  @spec subscribe(pid, binary) :: :ok
  def subscribe(subscriber, topic) when is_pid(subscriber),
    do:
      topic
      |> via_tuple()
      |> GenServer.cast({:add_subscriber, subscriber})

  @spec unsubscribe(pid, binary) :: :ok
  def unsubscribe(subscriber, topic) when is_pid(subscriber) and is_binary(topic),
    do:
      topic
      |> via_tuple()
      |> GenServer.cast({:remove_subscriber, subscriber})

  @spec subscribers(binary) :: MapSet.t(pid)
  def subscribers(topic) when is_binary(topic),
    do:
      topic
      |> via_tuple()
      |> GenServer.call(:subscribers)

  @spec handler(binary) :: pid | nil
  def handler(topic) when is_binary(topic),
    do:
      topic
      |> via_tuple
      |> GenServer.call(:handler)

  # Server callbacks

  def handle_call({:is_subscribed, subscriber}, _from, state) do
    {:reply, MapSet.member?(state.subscribers, subscriber), state}
  end

  def handle_call(:subscribers, _from, state) do
    {:reply, state.subscribers, state}
  end

  def handle_call(:handler, _from, state) do
    {:reply, state.handler, state}
  end

  def handle_call(data, _from, state) do
    Logger.info("Handle Call received data: #{inspect(data)}")
    {:reply, :ok, state}
  end

  @spec handle_cast(any, any, any) :: {:noreply, any} | {:reply, any, any}
  def handle_cast({:add_subscriber, subscriber}, _from, state) do
    subscribers = MapSet.put(state.subscribers, subscriber)
    state = %__MODULE__{state | subscribers: subscribers}
    {:reply, :ok, state}
  end

  def handle_cast({:remove_subscriber, subscriber}, _from, state) do
    {:reply, :ok, %__MODULE__{state | subscribers: MapSet.delete(state.subscribers, subscriber)}}
  end

  def handle_cast(data, state) do
    Logger.info("Received data: #{inspect(data)}")
    {:noreply, state}
  end

  def handle_info({:gun_up, conn_pid, protocol}, state) do
    Logger.info("Connection established: #{inspect(conn_pid)} using #{protocol}")
    {:noreply, state}
  end

  def handle_info({:gun_upgrade, conn_pid, stream_ref, ["websocket"], _headers}, state) do
    if conn_pid == state.ws.conn_pid and stream_ref == state.ws.stream_ref do
      Logger.info("WebSocket upgrade successful, subscribed to #{state.topic}")
      {:noreply, state}
    else
      Logger.error("Unexpected :gun_upgrade message")
      {:stop, :unexpected_message, state}
    end
  end

  def handle_info({:gun_ws, conn_pid, stream_ref, {:text, msg}}, state) do
    if conn_pid == state.ws.conn_pid and stream_ref == state.ws.stream_ref do
      Logger.info("Received message: #{msg}")

      state.subscribers
      |> MapSet.to_list()
      |> Enum.each(&send(&1, parse_pubsub_message(msg)))

      {:noreply, state}
    else
      Logger.error("Unexpected :gun_ws message")
      {:stop, :unexpected_message, state}
    end
  end

  def handle_info({:gun_ws, conn_pid, _, :ping}, state) do
    if conn_pid == state.ws.conn_pid do
      :ok = :gun.ws_send(conn_pid, :pong)
      {:noreply, state}
    else
      Logger.error("Unexpected :gun_ws message")
      {:stop, :unexpected_message, state}
    end
  end

  def handle_info({:gun_close, conn_pid, _stream_ref, _reason}, state) do
    if conn_pid == state.ws.conn_pid do
      Logger.info("WebSocket connection closed")
      # You might want to handle the reconnect logic here
      {:stop, :connection_closed, state}
    else
      {:noreply, state}
    end
  end

  def handle_info(
    {:gun_response, conn_pid, _stream_ref, :nofin, status_code, headers},
    state
  ) when conn_pid == state.ws.conn_pid do

  Logger.info("Received :gun_response with status code: #{status_code} and headers: #{inspect(headers)}")

  # You might want to handle different status codes differently.
  # For example, for a 405 status code (Method Not Allowed), you might want to log an error and terminate the GenServer.
  # For other status codes, you might want to do something else.
  case status_code do
    405 ->
      Logger.error("Received 405 Method Not Allowed in :gun_response")
      # {:stop, {:http_error, status_code}, state}
      {:noreply, state}

    _ ->
      # Handle other status codes if needed.
      {:noreply, state}
  end
end
  #     data ->
  #       Logger.info("Received data: #{inspect(data)}")

  #       state.subscribers
  #       |> MapSet.to_list()
  #       |> Enum.each(&send(&1, parse_pubsub_message(data)))

  #       {:noreply, state}
  #   end

  #   {:noreply, state}
  # end

  defp via_tuple(topic) when is_binary(topic) do
    Logger.debug("Registering via tuple for #{topic}")
    {:via, Registry, {@registry, topic}}
  end

  defp parse_pubsub_message(data) do
    if is_json?(data) do
      message = Message.new(data)
      if message.is_a?(Message) do
        {:ex_ipfs_pubsub_message, Multibase.decode!(message.data)}
      else
        {:raw_pubsub_message, data}
      end
    else
      {:raw_pubsub_message, data}
    end
  end

  defp is_json?(data) do
    case Jason.decode(data) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end
end
