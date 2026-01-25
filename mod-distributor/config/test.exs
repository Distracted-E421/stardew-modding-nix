import Config

# We don't run a server during test
config :mod_distributor, ModDistributorWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base_that_is_also_at_least_64_bytes_long_for_phoenix",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Use tmp storage in test
config :mod_distributor,
  mod_storage_path: "test/fixtures/mods"

