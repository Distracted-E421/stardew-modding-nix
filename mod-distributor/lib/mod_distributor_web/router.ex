defmodule ModDistributorWeb.Router do
  use ModDistributorWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ModDistributorWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ModDistributorWeb do
    pipe_through :browser

    # Main pages via LiveView
    live "/", HomeLive, :index
    live "/mods", ModBrowserLive, :index
    live "/download/:preset", DownloadLive, :preset
    live "/download", DownloadLive, :custom
    live "/guide", GuideLive, :index
  end

  # API for programmatic access
  scope "/api", ModDistributorWeb do
    pipe_through :api

    get "/catalog", CatalogController, :index
    get "/catalog/:mod_id", CatalogController, :show
    get "/presets", CatalogController, :presets
    get "/packages", PackageController, :index
    post "/packages/build", PackageController, :build
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:mod_distributor, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ModDistributorWeb.Telemetry
    end
  end
end

