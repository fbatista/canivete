import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    let targetElement = document.getElementById(this.element.hash.slice(1));
    this.element.addEventListener("click", (e) => {
      e.stopPropagation();
      e.preventDefault();
      targetElement.scrollIntoView();
      targetElement.classList.add("transition-all", "ring-8", "ring-purple-700");
      setTimeout(() => {
        targetElement.classList.remove("ring-8", "ring-purple-700");
      }, 500)
      
    });
  }
}
