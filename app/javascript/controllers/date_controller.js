import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {timestamp: String}

  connect() {
    this.renderDate()
  }

  renderDate() {
    const timestamp = new Date(this.timestampValue);

    // Format the date in the user's local timezone
    const options = {
      year: 'numeric', month: 'short', day: 'numeric',
      hour: '2-digit', minute: '2-digit', timeZoneName: 'short'
    }
    this.element.textContent = timestamp.toLocaleString(undefined, options)
  }
}
