defmodule ModDistributorWeb.CatalogController do
  use ModDistributorWeb, :controller

  def index(conn, _params) do
    mods = ModDistributor.Catalog.list_mods()
    metadata = ModDistributor.Catalog.get_metadata()
    
    json(conn, %{
      metadata: metadata,
      mods: mods
    })
  end

  def show(conn, %{"mod_id" => mod_id}) do
    case ModDistributor.Catalog.get_mod(mod_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Mod not found"})
      
      mod ->
        json(conn, mod)
    end
  end

  def presets(conn, _params) do
    presets = ModDistributor.Catalog.list_presets()
    json(conn, %{presets: presets})
  end
end

