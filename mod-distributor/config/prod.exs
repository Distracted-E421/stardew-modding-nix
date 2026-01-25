import Config

# Production configuration
config :mod_distributor, ModDistributorWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json"

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration
config :mod_distributor, ModDistributorWeb.Endpoint,
  # Binding to all interfaces for Tailscale access
  http: [ip: {0, 0, 0, 0}, port: 8080]

