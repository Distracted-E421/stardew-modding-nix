import Config

# For development, we disable any cache and enable debugging
config :mod_distributor, ModDistributorWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "dev_secret_key_base_that_should_be_at_least_64_bytes_long_for_phoenix_to_accept_it",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:mod_distributor, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:mod_distributor, ~w(--watch)]}
  ]

# Watch static and templates for browser reloading
config :mod_distributor, ModDistributorWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/mod_distributor_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Enable dev routes for dashboard
config :mod_distributor, dev_routes: true

# Set a higher stacktrace during development
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Use local storage in dev
config :mod_distributor,
  mod_storage_path: "priv/mods"

# Include HEEx debug annotations
config :phoenix_live_view,
  debug_heex_annotations: false,
  enable_expensive_runtime_checks: true

