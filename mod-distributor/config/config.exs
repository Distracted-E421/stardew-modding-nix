# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
import Config

# General application configuration
config :mod_distributor,
  # Path where mod files are stored
  mod_storage_path: System.get_env("MOD_STORAGE_PATH", "/srv/stardew-mods"),
  
  # Path to the mod catalog JSON
  catalog_path: System.get_env("MOD_CATALOG_PATH", "priv/catalog.json")

# Configures the endpoint
config :mod_distributor, ModDistributorWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ModDistributorWeb.ErrorHTML, json: ModDistributorWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ModDistributor.PubSub,
  live_view: [signing_salt: "stardew_mods"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.21.5",
  mod_distributor: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  mod_distributor: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config
import_config "#{config_env()}.exs"

