defmodule MyspacePubsub.Websocket do
  @moduledoc """
  An websocket client to handle data from the PubSub daemon
  """

  require Logger

  @enforce_keys [:conn_pid, :stream_ref]
  defstruct conn_pid: nil, stream_ref: nil

  @type t :: %__MODULE__{
          conn_pid: pid(),
          stream_ref: reference()
        }
  @doc """
  Creates a new websocket connection to the PubSub daemon.

  This is just a convenience function to create a new websocket connection
  to make the Topic handler more readable.
  """
  @spec new!(%{:host => any, :path => any, :port => char, optional(any) => any}) :: t()
  def new!(url) when is_struct(url) do
    {:ok, conn_pid} = :gun.open(to_charlist(url.host), url.port)
    stream_ref = :gun.ws_upgrade(conn_pid, to_charlist(url.path), [])

    %__MODULE__{
      conn_pid: conn_pid,
      stream_ref: stream_ref
    }
  end
end
