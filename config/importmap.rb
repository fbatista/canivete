# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

pin "flowbite", to: "https://cdn.jsdelivr.net/npm/flowbite@4.0.1/dist/flowbite.turbo.min.js"
pin "leaflet", to: "https://cdn.jsdelivr.net/npm/leaflet@1.9.4/+esm"
