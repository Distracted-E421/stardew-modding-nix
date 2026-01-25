defmodule ModDistributor.MixProject do
  use Mix.Project

  def project do
    [
      app: :mod_distributor,
      version: "0.1.0",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      
      # Docs
      name: "Stardew Mod Distributor",
      description: "Self-hosted mod distribution for Stardew Valley"
    ]
  end

  def application do
    [
      mod: {ModDistributor.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Phoenix
      {:phoenix, "~> 1.7.14"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:phoenix_live_view, "~> 0.20.17"},
      {:phoenix_live_dashboard, "~> 0.8.4"},
      
      # Assets
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:heroicons, "~> 0.5"},
      
      # HTTP client for downloading mods
      {:req, "~> 0.5"},
      
      # JSON handling
      {:jason, "~> 1.4"},
      
      # File handling
      {:zstream, "~> 0.6"},
      
      # Server
      {:plug_cowboy, "~> 2.7"},
      {:bandit, "~> 1.5"},
      
      # Telemetry
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.1"},
      
      # Dev/Test
      {:floki, ">= 0.0.0", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind mod_distributor", "esbuild mod_distributor"],
      "assets.deploy": [
        "tailwind mod_distributor --minify",
        "esbuild mod_distributor --minify",
        "phx.digest"
      ]
    ]
  end
end

