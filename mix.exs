defmodule MyspacePubsub.Mixfile do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :myspace_pubsub,
      version: "0.0.1",
      elixir: "~> 1.14",
      name: "Libp2p Pubsub for Elixir",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      name: "ex_ipfs",
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
      {:ex_ipfs, "~> 0.1.4"},
      {:gun, "~> 1.3"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:excoveralls, "~> 0.15", only: :test, runtime: false}
    ]
  end

  defp description() do
    "Elixir IPFS pubsub experiment module elixir."
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
