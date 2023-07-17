defmodule ExIpfsPubsub do
  @moduledoc """
  ExIpfsPubsub is where the Pubsub commands of the IPFS API reside.
  """
  alias ExIpfsPubsub.Topic
  use Tesla

  @api_url Application.compile_env(:ex_ipfs_pubsub, :api_url, "http://127.0.0.1:5002/api/v0")

  plug Tesla.Middleware.BaseUrl, @api_url
  #plug Tesla.Middleware.Headers, [{"Content-Type", "application/json"}]
  plug Tesla.Middleware.JSON

  require Logger

  @doc """
  Lists the topics that the node is subscribed to.
  """

  @spec ls() :: {:ok, list(binary)} | {:error, any | :invalid_response}
  def ls() do
    case get("/topics") do
      {:ok, %Tesla.Env{body: body}} when is_map(body) ->
        %{"topics" =>  topics} = body
        {:ok, topics}
      {:ok, _} ->
        {:error, :invalid_response}
      {:error, err} ->
        {:error, err}
    end
  end

  @doc """
  Lists the topics that the node is subscribed to.

  ## Usage
  ls!()

  """
  @spec ls!() :: list(binary)
  def ls!() do
    {:ok, %Tesla.Env{body: body}} = get("/topics")

    %{"topics" =>  topics} = body
    topics
  end

  @doc """
  Checks if a topic exists in the list of topics that the node is subscribed to.
  """
  @spec exists?(any) :: boolean
  def exists?(topic) do

    {:ok , topics} = ls()

    if topic in topics do
      true
    else
      false
    end

  end

  @doc """
  Subscribe to messages on a topic and listen for them.

  https://docs.ipfs.io/reference/http/api/#api-v0-pubsub-sub

  Messages are sent to the process as a tuple of `{:ex_ipfs_pubsub_topic_message, message}`.
  This should make it easy to pattern match on the messages in a receive do loop.

  ## Parameters
    `topic` - The topic to subscribe to.
    `pid`   - The process to send the messages to.

  ## Usage
  ```
  ExIpfsPubsub.sub(self(), "mytopic")
  ```

  Returns {:ok, pid} where pid is the pid of the GenServer that is listening for messages.
  Messages will be sent to the provided as a parameter to the function.
  """
  @spec sub(binary, pid) :: {:ok, pid} | ExIpfs.Api.error_response()
  def sub(topic, pid \\ self()) when is_binary(topic) do
    topic = Topic.new!(topic, pid)

    case ExIpfsPubsub.Supervisor.start_topic(topic) do
      {:ok, pid} ->
        Logger.info("Started topic: #{topic.topic}")
        {:ok, pid}

      {:error, {:already_started, handler}} ->
        Logger.info("Subscribing to topic: #{topic.topic}")
        ExIpfsPubsub.Topic.subscribe(pid, topic.topic)
        {:ok, handler}
    end
  end

  # FIXME: This is not working yet.
  # @spec publish(binary, binary) :: :ok
  # def publish(topic, message) when is_binary(topic) and is_binary(message) do
  #   Logger.info("Publishing message to topic: #{topic}")
  #   ExIpfsPubsub.Topic.publish(topic, message)
  # end

  @doc """
  Get next message from the Pubsub Topic in your inbox or wait for one to arrive.

  This is probably just useful for testing and is just here for the sweetness of it.
  https://www.youtube.com/watch?v=6jAVHBLvo2c

  It's just not good for your health, but OK for your soul.
  """
  @spec get_pubsub_topic_message :: any
  def get_pubsub_topic_message() do
    receive do
      {:ex_ipfs_pubsub_topic_message, message} -> message
    end
  end

  # @spec decode_strings({:error, any} | map | list) :: {:error, any} | map | list
  # defp decode_strings({:error, data}), do: {:error, data}

  # defp decode_strings(strings) when is_map(strings) do
  #   strings = Map.get(strings, "Strings", [])
  #   decoded_strings = Enum.map(strings, &Multibase.decode!/1)
  #   %{"Strings" => decoded_strings}
  # end

  # defp decode_strings(list), do: Enum.map(list, &decode_strings/1)
end
