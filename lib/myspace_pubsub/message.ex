defmodule MyspacePubsub.Message do
  @moduledoc false

  require Logger

  @enforce_keys [:from, :data]
  defstruct from: nil, data: nil

  @type t :: %__MODULE__{
          from: binary,
          data: binary
        }

  # Sample message:
  # {"from":"12D3KooWS9Wzyr6CprW7mZUdushaHvSFf2XGvPhtoBonUYabFECo","data":"Yo! This should be multiencoded for safe travels."}

  @spec new({:error, any}) :: {:error, any}
  def new({:error, data}), do: {:error, data}

  @spec new(map) :: t()
  def new(opts) when is_map(opts) do
    Logger.debug("Creating message from(#{inspect(opts)})")

    %__MODULE__{
      from: opts["from"],
      data: opts["data"]
    }
  end

  @spec new({:ok, map}) :: t()
  def new({:ok, opts}) when is_map(opts) do
    Logger.debug("Pubsub.Message.new/map(#{inspect(opts)})")
    new(opts)
  end

  @spec new(list) :: list(t())
  def new(response) when is_list(response) do
    Logger.debug("Pubsub.Message.new/list(#{inspect(response)})")
    Enum.map(response, &new/1)
  end

  @spec new(binary) :: binary()
  def new(response) when is_binary(response) do
    Logger.debug("Pubsub.Message.new/binary(#{inspect(response)})")
    new(Jason.decode!(response))
  end
end
