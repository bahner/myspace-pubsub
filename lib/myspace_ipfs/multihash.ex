defmodule MyspaceIpfs.MultiHash do
  @moduledoc """
  MyspaceIpfs.MultibaseCodec is a struct representing a hash. Seems much like a codec structure to me, but hey. Things may differ.
  """
  @enforce_keys [:name, :code]
  defstruct [:name, :code]

  @type t :: %__MODULE__{
          name: String.t(),
          code: non_neg_integer()
        }

  def gen_multihash(opts) do
    # code and name are required and must be present.
    %MyspaceIpfs.MultiHash{
      name: opts.name,
      code: opts.code
    }
  end
end
