import { Controller } from "@hotwired/stimulus"
import leaflet from "leaflet"

export default class extends Controller {
  static values = {
    latitude: Number,
    longitude: Number,
    address: String
  }

  connect() {
    this.map = leaflet.map(this.element, {
      zoomControl: false
    }).setView([this.latitudeValue, this.longitudeValue], 17)

    leaflet.marker([this.latitudeValue, this.longitudeValue]).addTo(this.map)
      .bindPopup(this.addressValue)
      .openPopup()

    leaflet.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    }).addTo(this.map);

    leaflet.control.zoom({ position: "topright" }).addTo(this.map)
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
      this.map = null
    }
  }
}
