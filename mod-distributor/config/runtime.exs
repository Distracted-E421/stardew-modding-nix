import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# having access to environment variables.

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "localhost"
  port = String.to_integer(System.get_env("PORT") || "8080")

  config :mod_distributor, ModDistributorWeb.Endpoint,
    url: [host: host, port: port, scheme: "http"],
    http: [
      ip: {0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # Mod storage path
  config :mod_distributor,
    mod_storage_path: System.get_env("MOD_STORAGE_PATH") || "/srv/stardew-mods"
end

