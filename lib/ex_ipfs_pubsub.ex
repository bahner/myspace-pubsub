defmodule ExIpfsPubsub do
  @moduledoc """
  ExIpfsPubsub is where the Pubsub commands of the IPFS API reside.
  """
  import ExIpfs.Api
  import ExIpfs.Utils
  alias ExIpfs.Multibase
  alias ExIpfsPubsub.Topic

  require Logger

  # @spec ls :: {:error, any} | {:ok, list}
  # @doc """
  # List the topics you are currently subscribed to.

  # https://docs.ipfs.io/reference/http/api/#api-v0-pubsub-ls
  # """
  # # @spec ls :: {:ok, ExIpfs.strings()} | ExIpfs.Api.error_response()
  # def ls do
  #   post_query("/pubsub/ls")
  #   |> decode_strings()
  #   |> Map.get("Strings")
  #   |> okify()
  # end

  # @doc """
  # List the peers you are currently connected to.

  # https://docs.ipfs.io/reference/http/api/#api-v0-pubsub-peers

  # ## Parameters
  #   `topic` - The topic to list peers for.
  # """
  # @spec peers(binary) :: {:ok, any} | ExIpfs.Api.error_response()
  # def peers(topic) do
  #   base64topic = Multibase.encode!(topic, [])

  #   post_query("/pubsub/peers?arg=#{base64topic}")
  #   |> Map.get("Strings")
  #   |> okify()
  # end

  @doc """
  Publish a message to a topic.

  https://docs.ipfs.io/reference/http/api/#api-v0-pubsub-pub

  ## Parameters
  ```
    `topic` - The topic to publish to.
    `data` - The data to publish.
  ```

  ## Usage
  ```
  ExIpfsPubsub.sub("mymessage", "mytopic")
  ```

  """
  @spec pub(binary, binary) :: {:ok, any} | ExIpfs.Api.error_response()
  def pub(data, topic) do
    multipart_content(data, "data")
    |> post_multipart("/pubsub/pub?arg=" <> Multibase.encode!(topic, []))
    |> okify()
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
