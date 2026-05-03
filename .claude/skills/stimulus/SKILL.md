---
name: stimulus
description: Create and manage Stimulus controllers for reactive UI interactions with Hotwire
license: MIT
---

## What I do
- Create Stimulus controllers for interactive UI elements
- Connect controllers to DOM elements via `data-controller` and `data-action`
- Manage controller lifecycle (initialize, connect, disconnect)
- Wire up Turbo events with Stimulus

## When to use me
- Adding interactive UI (toggles, dropdowns, form validation)
- Connecting JavaScript to DOM events
- Handling Turbo frame/stream events in JS
- Building reusable UI behaviors

## Project Conventions

### File Structure
```
app/javascript/
  application.js              — Importmap setup, Turbo, controllers, Flowbite
  controllers/
    application.js            — Stimulus Application.start()
    index.js                  — eagerLoadControllersFrom("controllers", application)
    dark_mode_controller.js   — Example controller
    swap_controller.js
    scroller_controller.js
    round_timer_controller.js
    date_controller.js
    date_calendar_controller.js
```

### Stimulus Application Setup
```javascript
// app/javascript/controllers/application.js
import { Application } from "@hotwired/stimulus"
const application = Application.start()
application.debug = false
window.Stimulus = application
export { application }
```

### Controller Registration
```javascript
// app/javascript/controllers/index.js
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
```

### Controller Skeleton
```javascript
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["elementName"];
  static values = { defaultValue: String };

  initialize() {
    // Called when controller is instantiated
  }

  connect() {
    // Called when element is connected to DOM
  }

  disconnect() {
    // Called when element is removed from DOM
  }

  myAction(event) {
    // Action handler
  }
}
```

### DOM Connection
```html
<!-- Single controller -->
<div data-controller="dark-mode">
  <button data-action="click->dark-mode#toggle">Toggle</button>
</div>

<!-- Multiple controllers -->
<div data-controller="controller-one controller-two">
  <button data-action="controller-one#action controller-two#action">
    Trigger both
  </button>
</div>

<!-- With targets -->
<div data-controller="scroller" data-scroller-target-name="scrollable">
  <div data-scroller-target="scrollable"></div>
</div>
```

### Action Syntax
- `click->controller#action` — click event on element triggers action
- `turbo:load->controller#action` — Turbo page load
- `turbo:frame-load->controller#action` — Turbo frame load
- `keyup->controller#action` — key events
- `input->controller#action` — input events
- Multiple actions: `click->controller#action1 click->controller#action2`

### Existing Controllers (Patterns)
- **dark_mode_controller.js**: localStorage + media query for theme; `initialize()` sets class on `<html>`; `toggle()` switches theme
- **swap_controller.js**: Handles pod participant swapping
- **scroller_controller.js**: Scroll behavior management
- **round_timer_controller.js**: Timer countdown logic
- **date_controller.js**: Date input handling
- **date_calendar_controller.js**: Calendar picker integration

### Turbo + Stimulus Integration
- Turbo page changes trigger `connect()`/`disconnect()` on controllers
- Turbo frames: controllers inside frames auto-connect when frame loads
- Use `turbo:frame-load` action for frame-specific initialization
- `target: "_top"` on turbo_frame_tag opens content in full page

### Importmap Setup
- `app/javascript/application.js` imports Turbo, controllers, Flowbite
- Controllers auto-loaded from `controllers/*_controller.js` via `stimulus-loading`
- Flowbite initialized for Bootstrap-compatible components

## Key Files
- `app/javascript/application.js` — Entry point with all imports
- `app/javascript/controllers/application.js` — Stimulus app initialization
- `app/javascript/controllers/index.js` — Controller registration
- `app/javascript/controllers/dark_mode_controller.js` — Example: initialize/toggle pattern
