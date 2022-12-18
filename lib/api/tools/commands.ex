defmodule MyspaceIPFS.Api.Tools.Commands do
  @moduledoc """
  MyspaceIPFS.Api.Commands is where the commands commands of the IPFS API reside.
  """
  import MyspaceIPFS

  @spec commands :: any
  def commands, do: post_query("/commands")

  @spec completion(binary) :: any
  def completion(shell), do: post_query("/commands/completion/" <> shell)
end
