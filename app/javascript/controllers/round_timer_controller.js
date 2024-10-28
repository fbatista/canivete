import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { startedAt: String, finishedAt: String, roundTime: Number };
  connect() {
    const started_at = new Date(this.startedAtValue);
    if (this.finishedAtValue == "") {
      this.updateTimer(started_at);
      setInterval(() => {
        this.updateTimer(started_at);
      }, 1000);
    } else {
      const finished_at = new Date(this.finishedAtValue);
      const ellapsed = ~~((finished_at - started_at) / 1000);
      const minutes = ~~(ellapsed / 60);
      const seconds = Math.abs(ellapsed % 60);

      this.element.innerHTML = `
        <svg class="w-2.5 h-2.5 me-1.5" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 20 20">
          <path d="M10 0a10 10 0 1 0 10 10A10.011 10.011 0 0 0 10 0Zm3.982 13.982a1 1 0 0 1-1.414 0l-3.274-3.274A1.012 1.012 0 0 1 9 10V6a1 1 0 0 1 2 0v3.586l2.982 2.982a1 1 0 0 1 0 1.414Z"/>
        </svg>
        Finished in ${minutes}:${seconds < 10 ? "0" + seconds : seconds}
        `;
    }
  }

  updateTimer(started_at) {
    const ellapsed = ~~((Date.now() - started_at) / 1000);
    const remaining = this.roundTimeValue - ellapsed;

    const minutes = ~~(remaining / 60);
    const seconds = Math.abs(remaining % 60);
    if (remaining < 0) {
      this.element.classList.add("text-red-500", "font-black", "text-2xl");
    }
    this.element.textContent = `${minutes}:${seconds < 10 ? "0" + seconds : seconds}`;
  }
}
