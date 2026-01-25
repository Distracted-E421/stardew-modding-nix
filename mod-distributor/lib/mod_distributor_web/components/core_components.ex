defmodule ModDistributorWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.
  
  Styled for the Stardew Valley aesthetic - warm, cozy, pixel-inspired.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @doc """
  Renders a modal dialog.
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-900/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-amber-500/20 relative hidden rounded-2xl bg-amber-50 p-8 shadow-2xl ring-2 ring-amber-600/30 transition"
            >
              <div class="absolute right-4 top-4">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="flex-none rounded-lg p-2 opacity-60 hover:opacity-100 hover:bg-amber-200/50"
                  aria-label="close"
                >
                  <.icon name="hero-x-mark" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                {render_slot(@inner_block)}
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-4 right-4 mr-2 w-80 sm:w-96 z-50 rounded-xl p-4 ring-1",
        @kind == :info && "bg-emerald-100 text-emerald-800 ring-emerald-500/20",
        @kind == :error && "bg-rose-100 text-rose-800 ring-rose-500/20"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-2 text-sm font-bold">
        <.icon :if={@kind == :info} name="hero-check-circle" class="h-5 w-5" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="h-5 w-5" />
        {@title}
      </p>
      <p class="mt-1 text-sm">{msg}</p>
      <button type="button" class="group absolute top-2 right-2 p-1" aria-label="close">
        <.icon name="hero-x-mark" class="h-4 w-4 opacity-60 group-hover:opacity-100" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title="Success!" flash={@flash} />
      <.flash kind={:error} title="Error!" flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title="Connection lost"
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        Attempting to reconnect...
        <.icon name="hero-arrow-path" class="ml-1 h-4 w-4 animate-spin" />
      </.flash>
      <.flash
        id="server-error"
        kind={:error}
        title="Server error"
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        Please wait while we get things back on track.
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a button.
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :variant, :string, default: "primary", values: ["primary", "secondary", "outline"]
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-xl px-6 py-3 text-base font-bold",
        "transition-all duration-200 ease-out",
        "focus:outline-none focus:ring-4",
        @variant == "primary" && "bg-gradient-to-b from-amber-500 to-amber-600 text-white shadow-lg shadow-amber-500/30 hover:from-amber-400 hover:to-amber-500 hover:shadow-amber-500/50 focus:ring-amber-300 active:from-amber-600 active:to-amber-700",
        @variant == "secondary" && "bg-gradient-to-b from-emerald-500 to-emerald-600 text-white shadow-lg shadow-emerald-500/30 hover:from-emerald-400 hover:to-emerald-500 hover:shadow-emerald-500/50 focus:ring-emerald-300 active:from-emerald-600 active:to-emerald-700",
        @variant == "outline" && "border-2 border-amber-600 text-amber-700 hover:bg-amber-100 focus:ring-amber-200",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Renders a card component.
  """
  attr :class, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true
  slot :header
  slot :footer

  def card(assigns) do
    ~H"""
    <div
      class={[
        "rounded-2xl bg-white/80 backdrop-blur-sm border-2 border-amber-200/50",
        "shadow-xl shadow-amber-900/5",
        "overflow-hidden",
        @class
      ]}
      {@rest}
    >
      <div :if={@header != []} class="border-b border-amber-200/50 bg-amber-50/50 px-6 py-4">
        {render_slot(@header)}
      </div>
      <div class="p-6">
        {render_slot(@inner_block)}
      </div>
      <div :if={@footer != []} class="border-t border-amber-200/50 bg-amber-50/50 px-6 py-4">
        {render_slot(@footer)}
      </div>
    </div>
    """
  end

  @doc """
  Renders a progress bar.
  """
  attr :value, :integer, default: 0
  attr :max, :integer, default: 100
  attr :class, :string, default: nil

  def progress(assigns) do
    ~H"""
    <div class={["w-full bg-amber-100 rounded-full h-4 overflow-hidden", @class]}>
      <div
        class="bg-gradient-to-r from-amber-400 to-amber-500 h-full rounded-full transition-all duration-300 ease-out"
        style={"width: #{@value / @max * 100}%"}
      >
      </div>
    </div>
    """
  end

  @doc """
  Renders a badge.
  """
  attr :class, :string, default: nil
  attr :variant, :string, default: "default", values: ["default", "success", "warning", "error"]

  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span
      class={[
        "inline-flex items-center rounded-full px-3 py-1 text-xs font-bold",
        @variant == "default" && "bg-amber-100 text-amber-700",
        @variant == "success" && "bg-emerald-100 text-emerald-700",
        @variant == "warning" && "bg-orange-100 text-orange-700",
        @variant == "error" && "bg-rose-100 text-rose-700",
        @class
      ]}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  Renders an icon from Heroicons.
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      time: 300,
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end
end

