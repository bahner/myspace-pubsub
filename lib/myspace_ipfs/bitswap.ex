defmodule MyspaceIpfs.Bitswap do
  @moduledoc """
  MyspaceIpfs.Bitswap is where the bitswap commands of the IPFS API reside.
  """
  import MyspaceIpfs.Api
  import MyspaceIpfs.Utils

  @typep okresult :: MySpaceIPFS.okresult()
  @typep peer_id :: MyspaceIpfs.peer_id()
  @type wantlist :: MyspaceIpfs.BitswapWantList.t()
  @type stat :: MyspaceIpfs.BitswapStat.t()
  @type ledger() :: MyspaceIpfs.BitswapLedger.t()
  @typep opts :: MyspaceIpfs.opts()

  @doc """
  Reprovide blocks to the network.
  """
  @spec reprovide() :: okresult()
  def reprovide() do
    post_query("/bitswap/reprovide")
    |> handle_api_response()
  end

  @doc """
  Get the current bitswap wantlist.

  ## Parameters
  https://docs.ipfs.tech/reference/kubo/rpc/#api-v0-bitswap-wantlist

  `peer` - The peer ID to get the wantlist for. Optional.
  """
  @spec wantlist() :: okresult()
  def wantlist() do
    post_query("/bitswap/wantlist")
    |> handle_api_response()
    |> Recase.Enumerable.convert_keys(&String.to_existing_atom/1)
    |> gen_wantlist()
    |> okify()
  end

  @spec wantlist(peer_id) :: {:ok, wantlist} | {:error, String.t()}
  def wantlist(peer) do
    post_query("/bitswap/wantlist?peer=" <> peer)
    |> handle_api_response()
    |> snake_atomize()
    |> gen_wantlist()
    |> okify()
  end

  @doc """
  Show some diagnostic information on the bitswap agent.

  ## Options
  https://docs.ipfs.tech/reference/kubo/rpc/#api-v0-bitswap-stat
  ```
  [
    `verbose`: <bool>, # Print extra information.
    `human`: <bool>, # Print sizes in human readable format (e.g., 1.2K 234M 2G).
  ]
  ```
  """
  @spec stat(opts) :: {:ok, [stat]} | {:error, any()}
  def stat(opts \\ []) do
    post_query("/bitswap/stat", query: opts)
    |> handle_api_response()
    |> snake_atomize()
    |> gen_stat()
  end

  @doc """
  Get the current bitswap ledger for a given peer.

  ## Parameters
  https://docs.ipfs.tech/reference/kubo/rpc/#api-v0-bitswap-ledger

  `peer` - The peer ID to get the ledger for.
  """
  @spec ledger(peer_id) :: {:ok, [ledger]} | {:error, any()}
  def ledger(peer) do
    post_query("/bitswap/ledger?arg=" <> peer)
    |> handle_api_response()
    |> snake_atomize()
    |> gen_ledger()
  end

  defp gen_ledger(opts) do
    %MyspaceIpfs.BitswapLedger{}
    |> struct(opts)
  end

  defp gen_wantlist(opts) do
    %MyspaceIpfs.BitswapWantList{}
    |> struct(opts)
  end

  defp gen_stat(opts) do
    %MyspaceIpfs.BitswapStat{}
    |> struct(opts)
  end
end