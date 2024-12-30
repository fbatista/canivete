import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    // this.element.href
    this.swapPlayer = null;
    this.swapPod = null;
  }

  selectPlayer(event) {
    let {
      params: { pod, player },
    } = event;

    if (this.swapPlayer == null) {
      this.swapPlayer = player;
      this.swapPod = pod;
      let li = event.currentTarget.closest("li");
      li.classList.add("outline-4", "outline-purple-500", "-outline-offset-4", "outline");
      event.stopPropagation();
      event.preventDefault();
    } else if (this.swapPlayer == player) {
      this.swapPlayer = null;
      this.swapPod = null;
      let li = event.currentTarget.closest("li");
      li.classList.remove("outline-4", "outline-purple-500", "-outline-offset-4", "outline");
      event.stopPropagation();
      event.preventDefault();
    } else {
      const url = new URL(event.currentTarget.href);
      url.searchParams.set("player", player);
      url.searchParams.set("pod", pod);
      url.searchParams.set("with_player", this.swapPlayer);
      url.searchParams.set("with_pod", this.swapPod);
      event.currentTarget.href = url.toString();
    }
  }
}
