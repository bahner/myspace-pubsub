defmodule MyspacePubsub.Mixfile do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :myspace_pubsub,
      version: "0.0.2",
      elixir: "~> 1.14",
      name: "Myspace libp2p PubSub for Elixir",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      source_url: "https://github.com/bahner/myspace-pubsub.git",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {MyspacePubsub.Application, []}
    ]
  end

  defp deps do
    [
      {:castore, "~> 1.0.3"},
      {:gun, "~> 1.3"},
      {:jason, "~> 1.4"},
      {:nanoid, "~> 2.1"},
      {:tesla, "~> 1.7"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:excoveralls, "~> 0.16", only: :test, runtime: false}
    ]
  end

  defp description() do
    """
    Myspace Libp2p Pubsub Library

    This library implements the Myspace Pubsub API for Elixir.

    The library is still in an early stage, but it is already usable.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*", "AUTHORS*"],
      maintainers: ["Lars Bahner"],
      licenses: ["GPLv3"],
      links: %{"GitHub" => "https://github.com/bahner/myspace-pubsub"}
    ]
  end
end
