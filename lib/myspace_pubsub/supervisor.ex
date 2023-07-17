defmodule MyspacePubsub.Supervisor do
  @moduledoc false

  use DynamicSupervisor, restart: :transient

  @typep topic :: MyspacePubsub.Topic.t()
  @registry :myspace_pubsub_registry

  @spec start_link(Init_args) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(init_args) do
    DynamicSupervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @spec init(any) :: :ignore | {:ok, DynamicSupervisor.sup_flags()}
  def init(_init_args) do
    # args = [strategy: :one_for_one, extra_arguments: [init_args]]
    args = [strategy: :one_for_one]
    DynamicSupervisor.init(args)
  end

  @spec start_topic(topic) :: DynamicSupervisor.on_start_child()
  def start_topic(topic) when is_struct(topic) do
    # topic_spec = {MyspacePubsub.Topic, topic}
    topic_spec = %{
      id: topic.base64url_topic,
      start: {MyspacePubsub.Topic, :start_link, [topic]}
    }

    DynamicSupervisor.start_child(__MODULE__, topic_spec)
  end

  @spec whereis_topic(binary) :: any
  def whereis_topic(topic) when is_binary(topic) do
    GenServer.call(@registry, {:whereis_name, topic})
  end
end
