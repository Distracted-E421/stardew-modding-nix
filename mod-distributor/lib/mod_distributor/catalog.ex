defmodule ModDistributor.Catalog do
  @moduledoc """
  Manages the mod catalog - metadata about all available mods.

  Loads mod information from catalog.json and provides querying capabilities.
  """
  use GenServer
  require Logger

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc "Get all mods in the catalog"
  def list_mods do
    GenServer.call(__MODULE__, :list_mods)
  end

  @doc "Get mods by category"
  def list_by_category(category) do
    GenServer.call(__MODULE__, {:list_by_category, category})
  end

  @doc "Get a specific mod by ID"
  def get_mod(mod_id) do
    GenServer.call(__MODULE__, {:get_mod, mod_id})
  end

  @doc "Get all available presets"
  def list_presets do
    GenServer.call(__MODULE__, :list_presets)
  end

  @doc "Get mods for a specific preset"
  def get_preset_mods(preset_name) do
    GenServer.call(__MODULE__, {:get_preset_mods, preset_name})
  end

  @doc "Get catalog metadata (version, game version, etc.)"
  def get_metadata do
    GenServer.call(__MODULE__, :get_metadata)
  end

  @doc "Reload the catalog from disk"
  def reload do
    GenServer.call(__MODULE__, :reload)
  end

  # Server Implementation

  @impl true
  def init(_opts) do
    case load_catalog() do
      {:ok, catalog} ->
        Logger.info("Loaded mod catalog with #{length(catalog.mods)} mods")
        {:ok, catalog}

      {:error, reason} ->
        Logger.warning("Failed to load mod catalog: #{inspect(reason)}. Starting with empty catalog.")
        {:ok, empty_catalog()}
    end
  end

  @impl true
  def handle_call(:list_mods, _from, state) do
    {:reply, state.mods, state}
  end

  @impl true
  def handle_call({:list_by_category, category}, _from, state) do
    mods = Enum.filter(state.mods, &(&1.category == category))
    {:reply, mods, state}
  end

  @impl true
  def handle_call({:get_mod, mod_id}, _from, state) do
    mod = Enum.find(state.mods, &(&1.id == mod_id))
    {:reply, mod, state}
  end

  @impl true
  def handle_call(:list_presets, _from, state) do
    {:reply, state.presets, state}
  end

  @impl true
  def handle_call({:get_preset_mods, preset_name}, _from, state) do
    case Map.get(state.presets, preset_name) do
      nil -> {:reply, {:error, :not_found}, state}
      mod_ids ->
        mods = Enum.filter(state.mods, &(&1.id in mod_ids))
        {:reply, {:ok, mods}, state}
    end
  end

  @impl true
  def handle_call(:get_metadata, _from, state) do
    metadata = %{
      modpack_version: state.modpack_version,
      game_version: state.game_version,
      smapi_version: state.smapi_version,
      total_mods: length(state.mods),
      categories: state.mods |> Enum.map(& &1.category) |> Enum.uniq() |> Enum.sort()
    }
    {:reply, metadata, state}
  end

  @impl true
  def handle_call(:reload, _from, state) do
    case load_catalog() do
      {:ok, catalog} ->
        Logger.info("Reloaded mod catalog with #{length(catalog.mods)} mods")
        {:reply, :ok, catalog}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  # Private Functions

  defp load_catalog do
    catalog_path = Application.get_env(:mod_distributor, :catalog_path, "priv/catalog.json")

    with {:ok, contents} <- File.read(catalog_path),
         {:ok, data} <- Jason.decode(contents, keys: :atoms) do
      # Handle both flat and nested category formats
      mods =
        cond do
          # Flat format with direct mods array
          is_list(data[:mods]) ->
            parse_mods(data[:mods])

          # Nested format with categories containing mods
          is_list(data[:categories]) ->
            data[:categories]
            |> Enum.flat_map(fn category ->
              category_mods = category[:mods] || []
              Enum.map(category_mods, fn mod ->
                # Use category name from parent if not in mod
                Map.put_new(mod, :category, category[:name] || "Uncategorized")
              end)
            end)
            |> parse_mods()

          true ->
            []
        end

      catalog = %{
        modpack_version: data[:version] || data[:modpack_version] || "0.0.0",
        game_version: data[:gameVersion] || data[:game_version] || "1.6.15",
        smapi_version: data[:smapiVersion] || data[:smapi_version] || "4.1.0",
        mods: mods,
        presets: data[:presets] || %{}
      }
      {:ok, catalog}
    end
  end

  defp parse_mods(mods) do
    mods
    |> Enum.with_index()
    |> Enum.map(fn {mod, idx} ->
      %{
        id: mod[:id] || generate_id(mod[:name], idx),
        name: mod[:name],
        version: mod[:version] || "1.0.0",
        author: mod[:author],
        category: mod[:category] || "Uncategorized",
        required: mod[:required] || false,
        nexus_id: mod[:nexus_id] || mod[:nexusId],
        dependencies: mod[:dependencies] || [],
        file_path: mod[:file_path] || mod[:filePath],
        description: mod[:description] || mod[:notes],
        size_mb: mod[:size_mb] || mod[:sizeMb] || 0
      }
    end)
  end

  defp generate_id(name, idx) when is_binary(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
    |> then(&"#{&1}-#{idx}")
  end

  defp generate_id(_, idx), do: "mod-#{idx}"

  defp empty_catalog do
    %{
      modpack_version: "0.0.0",
      game_version: "1.6.15",
      smapi_version: "4.1.0",
      mods: [],
      presets: %{}
    }
  end
end
