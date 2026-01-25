// Tailwind config for Stardew Mod Distributor
// Warm, cozy aesthetic inspired by Stardew Valley

const plugin = require("tailwindcss/plugin")

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
  ]
}
