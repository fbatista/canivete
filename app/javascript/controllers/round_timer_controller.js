import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {startedAt: String, roundTime: Number}
  connect() {
    const started_at = new Date(this.startedAtValue);
    setInterval(() => {
      const ellapsed = ~~((Date.now() - started_at) / 1000);
      const remaining = this.roundTimeValue - ellapsed;

      const minutes = ~~(remaining / 60);
      const seconds = Math.abs(remaining % 60);
      if (remaining < 0) {
        this.element.classList.add('text-red-500', 'font-bold')
      }
      this.element.textContent = `${minutes}:${seconds < 10 ? '0'+seconds : seconds}`
    }, 1000)
  }
}
