defmodule MyspaceIPFS.Commands do
  @moduledoc """
  MyspaceIPFS.Api.Commands is where the commands commands of the IPFS API reside.
  """
  import MyspaceIPFS.Api
  import MyspaceIPFS.Utils

  @typep okmapped :: MySpaceIPFS.okmapped()
  @typep opts :: MySpaceIPFS.opts()

  @doc """
  List all available commands.

  ## Options
  https://docs.ipfs.tech/reference/kubo/rpc/#api-v0-commands
  `flags` - Show command flags.
  """
  @spec commands(opts) :: okmapped()
  def commands(opts \\ []) do
    post_query("/commands", query: opts)
    |> handle_json_response()
  end

  @doc """
  Generate command autocompletion script.

  NB! These completions aren't actually in the API, but are generated by the
  client. Maybe they shoudn't be here?

  ## Parameters
  https://docs.ipfs.tech/reference/kubo/rpc/#api-v0-commands-completion
  `shell` - The shell to generate the autocompletion script for. Currently
  `bash` and `fish` are supported.
  """
  @spec completion(binary) :: okmapped()
  def completion(shell) do
    post_query("/commands/completion/" <> shell)
    |> handle_json_response()
  end
end
