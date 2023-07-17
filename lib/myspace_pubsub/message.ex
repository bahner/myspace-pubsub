defmodule MyspacePubsub.Message do
  @moduledoc false

  require Logger

  @enforce_keys [:from, :data]
  defstruct from: nil, data: nil

  @type t :: %__MODULE__{
          from: binary,
          data: binary
        }

  @spec new!(binary) :: t()
  def new!(response) when is_binary(response) do
    Logger.debug("Pubsub.Message.new!/binary(#{inspect(response)})")

    case new(response) do
      {:ok, message} -> message
      {:error, reason} -> raise "Failed to create message: #{reason}"
    end
  end

  @spec new(binary) :: {:ok, t()} | {:error, any()}
  def new(response) when is_binary(response) do
    Logger.debug("Pubsub.Message.new/binary(#{inspect(response)})")

    case Jason.decode(response) do
      {:ok, data} ->
        new(data)

      {:error, error} ->
        {:error, error}
    end
  end

  @spec new(map) :: {:ok, t()} | {:error, any()}
  def new(opts) when is_map(opts) do
    Logger.debug("Creating message from(#{inspect(opts)})")

    try do
      {:ok,
       %__MODULE__{
         from: opts["from"],
         data: opts["data"]
       }}
    rescue
      _ -> {:error, "Invalid data for creating a Message"}
    end
  end
end
