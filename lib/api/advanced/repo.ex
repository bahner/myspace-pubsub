defmodule MyspaceIPFS.Api.Advanced.Repo do
  @moduledoc """
  MyspaceIPFS.Api.Repo is where the repo commands of the IPFS API reside.
  """
  import MyspaceIPFS

  ## Currently throws an error due to the size of JSON response.
  @spec verify :: any
  def verify, do: post_query("/repo/verify")

  @spec version :: any
  def version, do: post_query("/repo/version")

  @spec stat :: any
  def stat, do: post_query("/repo/stat")

  @spec gc :: any
  def gc, do: post_query("/repo/gc")
end
