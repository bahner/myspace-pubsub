defmodule MyspaceIPFS.Api.Advanced.Name do
  @moduledoc """
  MyspaceIPFS.Api.Name is where the name commands of the IPFS API reside.
  """
  import MyspaceIPFS

  @spec publish(binary) :: any
  def publish(path), do: post_query("/name/publish?arg=", path)

  @spec resolve :: any
  def resolve, do: post_query("/name/resolve")
end
