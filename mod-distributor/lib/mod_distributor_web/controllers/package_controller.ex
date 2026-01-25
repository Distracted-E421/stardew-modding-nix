defmodule ModDistributorWeb.PackageController do
  use ModDistributorWeb, :controller

  def index(conn, _params) do
    packages = ModDistributor.Packager.list_packages()
    json(conn, %{packages: packages})
  end

  def build(conn, %{"preset" => preset}) do
    case ModDistributor.Packager.create_preset_package(preset) do
      {:ok, path} ->
        filename = Path.basename(path)
        json(conn, %{
          success: true,
          download_url: "/downloads/#{filename}"
        })
      
      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{success: false, error: inspect(reason)})
    end
  end

  def build(conn, %{"mod_ids" => mod_ids}) when is_list(mod_ids) do
    case ModDistributor.Packager.create_custom_package(mod_ids) do
      {:ok, path} ->
        filename = Path.basename(path)
        json(conn, %{
          success: true,
          download_url: "/downloads/#{filename}"
        })
      
      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{success: false, error: inspect(reason)})
    end
  end

  def build(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Must provide 'preset' or 'mod_ids'"})
  end
end

