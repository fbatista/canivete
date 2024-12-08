import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    let targetElement = document.getElementById(this.element.href.slice(1));
    this.element.addEventListener("click", (e) => {
      e.stopPropagation();
      e.preventDefault();
      targetElement.scrollIntoView();
    });
  }
