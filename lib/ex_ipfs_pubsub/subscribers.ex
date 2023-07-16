defmodule ExIpfsPubsub.Subscribers do
  @moduledoc false

  # This module is a registry for all topics.
  # Mostly to preserve the subscribers of a topic when the topic handler is restarted.

  use Agent, restart: :transient

  @typep subscribers :: MapSet.t(pid)

  @spec start_link(any) :: {:error, any} | {:ok, pid}
  def start_link(_null) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc """
  Get the subscribers of a topic. Returns an empty MapSet if the topic is not registered.
  """
  @spec get_topic(binary) :: MapSet.t(pid)
  def get_topic(topic) when is_binary(topic) do
    Agent.get(__MODULE__, &Map.get(&1, topic, MapSet.new()))
    |> MapSet.to_list()
    |> Enum.filter(&Process.alive?/1)
    |> MapSet.new()
  end

  @doc """
  Register a new topic with its subscribers.
  If the topic is already registered, the old, live subscribers are silentrly merged.
  """
  @spec add_topic(binary, subscribers) :: :ok
  def add_topic(topic, subscribers) when is_binary(topic) and is_map(subscribers) do
    subscribers = MapSet.union(subscribers, get_topic(topic))
    Agent.update(__MODULE__, &Map.put(&1, topic, subscribers))
  end

  @spec remove_topic(binary) :: :ok
  def remove_topic(topic) when is_binary(topic) do
    Agent.update(__MODULE__, &Map.delete(&1, topic))
  end

  @spec list_topics() :: [binary]
  def list_topics() do
    Agent.get(__MODULE__, &Map.keys(&1))
  end

  @doc """
  List all subscribers of all topics. This may be used for a broadcast.
  """
  @spec list_subscribers() :: MapSet.t(pid)
  def list_subscribers() do
    Agent.get(__MODULE__, &Map.values(&1))
    |> Enum.map(&MapSet.to_list/1)
    |> List.flatten()
    |> Enum.filter(&Process.alive?/1)
    |> MapSet.new()
  end

  @spec get_all :: map
  def get_all() do
    Agent.get(__MODULE__, & &1)
  end
end
