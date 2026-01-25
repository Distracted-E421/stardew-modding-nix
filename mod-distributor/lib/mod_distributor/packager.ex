defmodule ModDistributor.Packager do
  @moduledoc """
  Handles creating downloadable mod packages.
  
  Can create ZIP archives from:
  - Pre-built presets
  - Custom mod selections
  - Individual mods
  """
  use GenServer
  require Logger

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Create a package for a preset.
  Returns {:ok, package_path} or {:error, reason}
  """
  def create_preset_package(preset_name, opts \\ []) do
    GenServer.call(__MODULE__, {:create_preset_package, preset_name, opts}, :infinity)
  end

  @doc """
  Create a package for specific mod IDs.
  Returns {:ok, package_path} or {:error, reason}
  """
  def create_custom_package(mod_ids, opts \\ []) do
    GenServer.call(__MODULE__, {:create_custom_package, mod_ids, opts}, :infinity)
  end

  @doc """
  Get the path to a pre-built preset package if it exists.
  """
  def get_preset_path(preset_name) do
    GenServer.call(__MODULE__, {:get_preset_path, preset_name})
  end

  @doc """
  List all available pre-built packages.
  """
  def list_packages do
    GenServer.call(__MODULE__, :list_packages)
  end

  @doc """
  Estimate the size of a package.
  """
  def estimate_size(mod_ids) do
    GenServer.call(__MODULE__, {:estimate_size, mod_ids})
  end

  # Server Implementation

  @impl true
  def init(_opts) do
    mod_path = Application.get_env(:mod_distributor, :mod_storage_path, "priv/mods")
    cache_path = Path.join(mod_path, "cache")
    
    # Ensure cache directory exists
    File.mkdir_p!(cache_path)
    
    state = %{
      mod_path: mod_path,
      cache_path: cache_path,
      in_progress: %{}  # Track ongoing package operations
    }
    
    {:ok, state}
  end

  @impl true
  def handle_call({:create_preset_package, preset_name, opts}, from, state) do
    # Check for pre-built package first
    preset_file = Path.join(state.cache_path, "#{preset_name}.zip")
    
    if File.exists?(preset_file) and not Keyword.get(opts, :force_rebuild, false) do
      {:reply, {:ok, preset_file}, state}
    else
      # Build the package asynchronously and track progress
      task = Task.async(fn ->
        build_preset_package(preset_name, state.mod_path, preset_file)
      end)
      
      new_state = put_in(state.in_progress[task.ref], {from, preset_name})
      {:noreply, new_state}
    end
  end

  @impl true
  def handle_call({:create_custom_package, mod_ids, _opts}, from, state) do
    # Generate unique filename for custom package
    hash = :crypto.hash(:md5, Enum.join(Enum.sort(mod_ids), ",")) |> Base.encode16(case: :lower)
    package_file = Path.join(state.cache_path, "custom_#{hash}.zip")
    
    if File.exists?(package_file) do
      {:reply, {:ok, package_file}, state}
    else
      task = Task.async(fn ->
        build_custom_package(mod_ids, state.mod_path, package_file)
      end)
      
      new_state = put_in(state.in_progress[task.ref], {from, "custom"})
      {:noreply, new_state}
    end
  end

  @impl true
  def handle_call({:get_preset_path, preset_name}, _from, state) do
    preset_file = Path.join(state.cache_path, "#{preset_name}.zip")
    
    if File.exists?(preset_file) do
      {:reply, {:ok, preset_file}, state}
    else
      {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call(:list_packages, _from, state) do
    packages = 
      state.cache_path
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".zip"))
      |> Enum.map(fn filename ->
        path = Path.join(state.cache_path, filename)
        stat = File.stat!(path)
        %{
          name: Path.rootname(filename),
          filename: filename,
          size_bytes: stat.size,
          modified: stat.mtime
        }
      end)
    
    {:reply, packages, state}
  end

  @impl true
  def handle_call({:estimate_size, mod_ids}, _from, state) do
    mods = ModDistributor.Catalog.list_mods()
    
    size_mb = 
      mods
      |> Enum.filter(&(&1.id in mod_ids))
      |> Enum.reduce(0, &(&1.size_mb + &2))
    
    {:reply, size_mb, state}
  end

  @impl true
  def handle_info({ref, result}, state) do
    # Task completed
    case Map.pop(state.in_progress, ref) do
      {{from, _name}, new_in_progress} ->
        Process.demonitor(ref, [:flush])
        GenServer.reply(from, result)
        {:noreply, %{state | in_progress: new_in_progress}}
      
      {nil, _} ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, reason}, state) do
    # Task failed
    case Map.pop(state.in_progress, ref) do
      {{from, _name}, new_in_progress} ->
        GenServer.reply(from, {:error, reason})
        {:noreply, %{state | in_progress: new_in_progress}}
      
      {nil, _} ->
        {:noreply, state}
    end
  end

  # Private Functions

  defp build_preset_package(preset_name, mod_path, output_path) do
    case ModDistributor.Catalog.get_preset_mods(preset_name) do
      {:ok, mods} ->
        mod_ids = Enum.map(mods, & &1.id)
        build_zip(mod_ids, mod_path, output_path)
      
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_custom_package(mod_ids, mod_path, output_path) do
    build_zip(mod_ids, mod_path, output_path)
  end

  defp build_zip(mod_ids, mod_path, output_path) do
    Logger.info("Building package with #{length(mod_ids)} mods -> #{output_path}")
    
    # Get mod metadata
    mods = ModDistributor.Catalog.list_mods()
    selected_mods = Enum.filter(mods, &(&1.id in mod_ids))
    
    # Build list of files to include
    files = 
      selected_mods
      |> Enum.flat_map(fn mod ->
        source_dir = Path.join(mod_path, mod.file_path)
        
        if File.exists?(source_dir) do
          source_dir
          |> Path.join("**/*")
          |> Path.wildcard()
          |> Enum.filter(&File.regular?/1)
          |> Enum.map(fn file ->
            relative = Path.relative_to(file, mod_path)
            {String.to_charlist(file), String.to_charlist(relative)}
          end)
        else
          Logger.warning("Mod directory not found: #{source_dir}")
          []
        end
      end)
    
    if Enum.empty?(files) do
      {:error, :no_files}
    else
      # Create ZIP file
      case :zip.create(String.to_charlist(output_path), files) do
        {:ok, _} -> {:ok, output_path}
        {:error, reason} -> {:error, reason}
      end
    end
  end
end

