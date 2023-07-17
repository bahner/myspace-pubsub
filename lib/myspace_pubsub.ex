defmodule MyspacePubsub do
  @moduledoc """
  MyspacePubsub is where the Pubsub commands of the IPFS API reside.
  """

  alias MyspacePubsub.Topic
  alias MyspacePubsub.Api
  require Logger

  @doc """
  Lists the topics that the node is subscribed to.
  """
  @spec ls() :: {:ok, list(binary)} | {:error, any | :invalid_response}
  def ls() do
    case Api.get("/topics") do
      {:ok, %Tesla.Env{body: body}} when is_map(body) ->
        %{"topics" => topics} = body
        {:ok, topics}

      {:ok, _} ->
        {:error, :invalid_response}

      {:error, err} ->
        {:error, err}
    end
  end

  @doc """
  Lists the topics that the node is subscribed to.
  """
  @spec ls!() :: list(binary)
  def ls!() do
    {:ok, %Tesla.Env{body: body}} = Api.get("/topics")
    %{"topics" => topics} = body
    topics
  end

  @doc """
  Checks if a topic exists in the list of topics that the node is subscribed to.
  ## Parameters
    `topic` - The topic to check for.
  """
  @spec exists?(binary) :: boolean
  def exists?(topic) do
    {:ok, topics} = ls()
    topic in topics
  end

  @doc """
    Subscribe to messages on a topic and listen for them.
    https://docs.ipfs.io/reference/http/api/#api-v0-pubsub-sub
    Messages are sent to the process as a tuple of `{:myspace_pubsub_topic_message, message}`.
    This should make it easy to pattern match on the messages in a receive do loop.

    ## Parameters
      `topic` - The topic to subscribe to.
      `pid`   - The process to send the messages to.

    ## Usage
    MyspacePubsub.sub("mytopic")
    MyspacePubsub.sub("mytopic", self()) # Same as above
    MyspacePubsub.sub("mytopic", pid) # Send messages to a specific process

  Returns {:ok, pid} where pid is the pid of the GenServer that is listening for messages.
  Messages will be sent to the provided as a parameter to the function.
  """
  #  @spec sub(binary, pid) :: {:ok, pid} | {:error, any}
  @spec sub(binary, pid) :: any
  def sub(topic, pid \\ self()) when is_binary(topic) do
    topic = Topic.new!(topic, pid)

    case MyspacePubsub.Supervisor.start_topic(topic) do
      {:ok, pid} ->
        Logger.info("Started topic: #{topic.topic}")
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info("Subscribing to topic: #{topic.topic}")
        MyspacePubsub.Topic.subscribe(pid, topic.topic)
        {:ok, pid}
    end
  end

  @doc """
  Get next message from the Pubsub Topic in your inbox or wait for one to arrive.
  This is probably just useful for testing and is just here for the sweetness of it.
  https://www.youtube.com/watch?v=6jAVHBLvo2c
  It's just not good for your health, but OK for your soul.
  """
  @spec get_pubsub_topic_message :: any
  def get_pubsub_topic_message() do
    receive do
      {:myspace_pubsub_message, message} -> message
    end
  end

  @doc """
  Lists the peers that are participating in the given topic.
  ## Parameters
    `topic` - The topic to list peers for.
  ## Returns
  A tuple `{:ok, peers}` on success, where peers is a list of peer identifiers.
  Returns `{:error, reason}` on failure.
  """
  @spec peers(binary) :: {:ok, list(binary)} | {:error, any | :invalid_response}
  def peers(topic) when is_binary(topic) do
    case Api.get("/topics/" <> topic <> "/peers") do
      {:ok, %Tesla.Env{body: body}} when is_map(body) ->
        %{"peers" => peers} = body
        {:ok, peers}

      {:ok, _} ->
        {:error, :invalid_response}

      {:error, err} ->
        {:error, err}
    end
  end

  @doc """
  Lists the peers that are participating in the given topic.
  ## Parameters
    `topic` - The topic to list peers for.
  ## Returns
  A list of peer identifiers.
  """
  @spec peers!(binary) :: list(binary)
  def peers!(topic) when is_binary(topic) do
    {:ok, %Tesla.Env{body: body}} = Api.get("/topics/" <> topic <> "/peers")
    %{"peers" => peers} = body
    peers
  end
end
