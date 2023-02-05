defmodule MyspaceIPFS.CommandsCommand do
  @moduledoc """
  MyspaceIPFS.Commands is where the commands commands of the IPFS API reside.
  """

  defstruct name: nil, options: [], subcommands: []

  @type t :: %__MODULE__{
          name: binary,
          options: list,
          subcommands: list
        }

  require Logger

  @doc """
  Generate command struct for a command object
  """
  @spec new({:error, map}) :: {:error, map}
  def new({:error, data}) do
    {:error, data}
  end

  @spec new(map) :: t
  def new(opts) do
    %__MODULE__{
      name: opts["Name"],
      options: opts["Options"],
      subcommands: Enum.map(opts["Subcommands"], &gen_commands/1)
    }
  end

  defp gen_commands(command) when is_map(command) do
    if has_subcommands?(command) do
      Logger.debug("Generating subcommands for #{command["Name"]}")
      %{command | subcommands: Enum.map(command["Subcommands"], &gen_commands/1)}
    else
      Logger.debug("Generating command #{command["Name"]}")
      new(command)
    end
  end

  defp has_subcommands?(command) when is_map(command) do
    Map.has_key?(command, :subcommands) && command.subcommands != []
  end
end