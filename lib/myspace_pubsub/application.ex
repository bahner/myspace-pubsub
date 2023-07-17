defmodule MyspacePubsub.Application do
  @moduledoc false
  use Application

  @registry :myspace_pubsub_registry
  @supervisor MyspacePubsub.Supervisor
  @subscribers MyspacePubsub.Subscribers

  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    children = [
      {Registry, [keys: :unique, name: @registry]},
      {@supervisor, name: @supervisor},
      {@subscribers, name: @subscribers}
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
