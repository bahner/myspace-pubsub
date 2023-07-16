defmodule ExIpfsPubsub.Topic do
  @moduledoc false

  use GenServer, restart: :transient

  require Logger
  alias ExIpfs.ApiStreamingClient
  alias ExIpfs.Multibase
  alias ExIpfsPubsub.Message
  alias ExIpfsPubsub.Subscribers

  @api_url Application.compile_env(:ex_ipfs, :api_url, "http://127.0.0.1:5001/api/v0")
  @registry :ex_ipfs_pubsub_registry

  @enforce_keys [:base64url_topic, :handler, :subscribers, :topic]
  defstruct base64url_topic: nil, handler: nil, subscribers: MapSet.new(), topic: nil, conn_pid: nil, stream_ref: nil

  @type t :: %__MODULE__{
          base64url_topic: binary | nil,
          handler: pid | nil,
          subscribers: MapSet.t(pid),
          topic: binary
        }

  @spec new!(binary, pid) :: t()
  def new!(topic, subscriber) when is_pid(subscriber) do
    %__MODULE__{
      base64url_topic: Multibase.encode!(topic, b: "base64url"),
      handler: nil,
      subscribers: MapSet.new([subscriber]),
      topic: topic
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
    {:ok, conn_pid} = :gun.open(to_charlist(url.host), url.port)
    stream_ref = :gun.ws_upgrade(conn_pid, to_charlist(url.path), [])
    state = %__MODULE__{state | conn_pid: conn_pid, stream_ref: stream_ref}
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

  def handle_cast(:subscribe, state) do
    Logger.info("Starting subscription for #{state.topic}")

    url = "#{@api_url}/pubsub/sub?arg=#{state.base64url_topic}"

    # Set self( ) as the target for the ApiStreamingClient
    # Well extract the end target, when parsed.
    ApiStreamingClient.new(
      self(),
      url,
      :infinity
    )

    {:noreply, state}
  end

  def handle_cast(data, state) do
    Logger.info("Received data: #{inspect(data)}")
    {:noreply, state}
  end


  def handle_info({:gun_upgrade, conn_pid, stream_ref, ["websocket"], _headers}, state) do
    if conn_pid == state.conn_pid and stream_ref == state.stream_ref do
      Logger.info("WebSocket upgrade successful, subscribed to #{state.topic}")
      {:noreply, state}
    else
      Logger.error("Unexpected :gun_upgrade message")
      {:stop, :unexpected_message, state}
    end
  end

  def handle_info({:gun_ws, conn_pid, stream_ref, {:text, msg}}, state) do
    if conn_pid == state.conn_pid and stream_ref == state.stream_ref do
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

  def handle_info({:gun_ws, conn_pid, stream_ref, :ping}, state) do
    if conn_pid == state.conn_pid and stream_ref == state.stream_ref do
      :ok = :gun.ws_send(conn_pid, stream_ref, :pong)
      {:noreply, state}
    else
      Logger.error("Unexpected :gun_ws message")
      {:stop, :unexpected_message, state}
    end
  end

  def handle_info({:gun_close, conn_pid, _stream_ref, _reason}, state) do
    if conn_pid == state.conn_pid do
      Logger.info("WebSocket connection closed")
      # You might want to handle the reconnect logic here
      {:stop, :connection_closed, state}
    else
      {:noreply, state}
    end
  end


  # def handle_info({:hackney_response, _ref, data}, state) do
  #   case data do
  #     {:status, 200, _} ->
  #       Logger.info("Subscribed to #{state.topic}")
  #       {:noreply, state}

  #     {:headers, headers} ->
  #       Logger.info("Headers: #{inspect(headers)}")
  #       {:noreply, state}

  #     {:data, data} ->
  #       Logger.info("Data: #{inspect(data)}")
  #       {:noreply, state}

  #     {:done, _} ->
  #       Logger.info("Done")
  #       {:noreply, state}

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
    message = Message.new(data)
    {:ex_ipfs_pubsub_message, Multibase.decode!(message.data)}
  end
end
