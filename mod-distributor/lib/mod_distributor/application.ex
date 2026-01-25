defmodule ModDistributor.Application do
  @moduledoc """
  The ModDistributor OTP Application.
  
  Manages the supervision tree for the Stardew Valley mod distribution service.
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Telemetry supervisor
      ModDistributorWeb.Telemetry,
      # PubSub system for LiveView
      {Phoenix.PubSub, name: ModDistributor.PubSub},
      # Mod catalog GenServer - loads and caches mod metadata
      ModDistributor.Catalog,
      # Packager for creating download archives
      ModDistributor.Packager,
      # Phoenix endpoint (must be last)
      ModDistributorWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: ModDistributor.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    ModDistributorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

