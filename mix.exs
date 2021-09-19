defmodule Mantis.MixProject do
  use Mix.Project

  @version "0.1.2"

  def project do
    [
      app: :mantis,
      version: @version,
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      description: description(),
      package: package(),
      name: "Mantis",
      source_url: "https://github.com/spawnfest/mantis",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Mantis.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:hlclock, "~> 1.0"},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:local_cluster, "~> 1.0", only: [:dev, :test]},
      {:schism, "~> 1.0", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, "~> 0.14"},
      {:mox, "~> 1.0", only: :test}
    ]
  end

  def aliases do
    [
      test: ["test --no-start"]
    ]
  end

  def description do
    """
    Mantis is a distributed KV store built on distributed erlang, LWW Register
    CRDTS, and Hybrid Logical Clocks.
    """
  end

  def package do
    [
      name: "mantis",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/spawnfest/mantis"}
    ]
  end

  def docs do
    [
      source_ref: "v#{@version}",
      source_url: "https://github.com/spawnfest/mantis",
      main: "Mantis"
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]
end
