// Stardew Mod Distributor - Main JavaScript
// Phoenix LiveView client

import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Custom hooks for enhanced interactivity
let Hooks = {}

// Download progress hook
Hooks.DownloadProgress = {
  mounted() {
    this.handleEvent("download_progress", ({percent, message}) => {
      this.el.style.width = `${percent}%`
      const messageEl = document.getElementById("progress-message")
      if (messageEl) messageEl.innerText = message
    })
  }
}

// Clipboard copy hook
Hooks.CopyToClipboard = {
  mounted() {
    this.el.addEventListener("click", () => {
      const text = this.el.dataset.copy
      navigator.clipboard.writeText(text).then(() => {
        const original = this.el.innerText
        this.el.innerText = "Copied!"
        setTimeout(() => this.el.innerText = original, 2000)
      })
    })
  }
}

// Connection status
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: Hooks,
  longPollFallbackMs: 2500
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#f59e0b"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// Connect if there are any LiveViews on the page
liveSocket.connect()

// Expose liveSocket on window for debugging
window.liveSocket = liveSocket

// Smooth scroll for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
  anchor.addEventListener('click', function (e) {
    e.preventDefault()
    const target = document.querySelector(this.getAttribute('href'))
    if (target) {
      target.scrollIntoView({ behavior: 'smooth' })
    }
  })
})

