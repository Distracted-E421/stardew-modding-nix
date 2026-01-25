// Tailwind config for Stardew Mod Distributor
// Warm, cozy aesthetic inspired by Stardew Valley

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/mod_distributor_web.ex",
    "../lib/mod_distributor_web/**/*.*ex"
  ],
  theme: {
    extend: {
      fontFamily: {
        'nunito': ['Nunito', 'system-ui', 'sans-serif'],
      },
      colors: {
        // Stardew-inspired warm palette
        stardew: {
          brown: '#8b6914',
          gold: '#f5c211',
          green: '#4a7c59',
          blue: '#5b8ca4',
          pink: '#e8a4c4',
          cream: '#fff8e7',
        },
      },
      animation: {
        'bounce-slow': 'bounce 2s infinite',
      },
      boxShadow: {
        'warm': '0 4px 14px 0 rgba(251, 191, 36, 0.15)',
        'warm-lg': '0 10px 40px -10px rgba(251, 191, 36, 0.25)',
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    // Adds Heroicons (from heroicons.com) for Phoenix usage
    plugin(function({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "../deps/heroicons/optimized")
      let values = {}
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
        ["-micro", "/16/solid"]
      ]
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach(file => {
          let name = path.basename(file, ".svg") + suffix
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) }
        })
      })
      matchComponents({
        "hero": ({ name, fullPath }) => {
          let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
          let size = theme("spacing.6")
          if (googlesuffix == "-mini") {
            size = theme("spacing.5")
          } else if (name.endsWith("-micro")) {
            size = theme("spacing.4")
          }
          return {
            [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
            "-webkit-mask": `var(--hero-${name})`,
            "mask": `var(--hero-${name})`,
            "mask-repeat": "no-repeat",
            "background-color": "currentColor",
            "vertical-align": "middle",
            "display": "inline-block",
            "width": size,
            "height": size
          }
        }
      }, { values })
    })
  ]
}

