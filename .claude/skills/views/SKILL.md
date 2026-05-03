---
name: views
description: Write views using Hotwire (Turbo frames/streams), Tailwind CSS 4, Flowbite, and Herb (ERB) templates
license: MIT
---

## What I do
- Write ERB templates with Herb syntax
- Style with Tailwind CSS 4 and Flowbite components
- Use Turbo frames for partial updates, Turbo streams for live notifications
- Structure views with layouts and content_for blocks

## When to use me
- Adding new views or partials
- Modifying existing templates
- Adding interactive elements with Turbo
- Building UI components with Tailwind/Flowbite

## Project Conventions

### File Locations
- Views: `app/views/<controller_name>/action.html.erb`
- Layouts: `app/views/layouts/application.html.erb`
- Partials: `app/views/<controller_name>/_<partial>.html.erb`
- Modal layouts: `app/views/layouts/modal.html.erb`

### Layout Structure (application.html.erb)
- Fixed header with navbar (nav with logo, theme toggle, organizer mode switch, auth)
- Main content area in grid layout: `grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4`
- Footer with GitHub link
- Modal turbo frame: `<%= turbo_frame_tag "modal", target: "_top" %>`
- Dark mode: `bg-gray-50 dark:bg-gray-900` pattern throughout

### Turbo Patterns
- **Turbo Frame**: `<%= turbo_frame_tag "frame_id" %>` — replace only frame content
- **Turbo Stream**: For live notifications, form submission responses
- **Turbo Method**: `data: { "turbo-method": :delete }` for Turbo-preflighted DELETE requests
- **Modal Pattern**: Links open modals via `data: { turbo_frame: "modal" }`
- **Turbo Track**: `<%= stylesheet_link_tag ..., "data-turbo-track": "reload" %>`

### Layout Content Blocks
```erb
<% content_for :sub_navigation do %>
  <%= yield :sub_navigation %>
<% end %>
```
- `content_for` defines a block, `yield :name` renders it
- Used for breadcrumbs, tab navigation, sub-nav sections

### Tailwind CSS 4
- **Utility-first**: Apply classes directly in templates
- **Dark mode**: `dark:` prefix throughout (`dark:text-white`, `dark:bg-gray-800`)
- **Responsive prefixes**: `md:`, `lg:`, `xl:`, `2xl:`
- **Flowbite components**: Toggle switches, badges, dropdowns, cards
- **Phosphor Icons**: `icon('icon-name')` helper
- **Container queries**: `@tailwindcss/container-queries` plugin available
- **Forms plugin**: `@tailwindcss/forms` for styled form inputs
- **Typography**: `@tailwindcss/typography` for prose content

### Form Pattern
- Use `form_with` or `form_for` with model binding
- Tailwind-styled inputs with Flowbite patterns
- Validation errors displayed inline after form fields
- `status: :unprocessable_entity` on render :edit for validation failures

### View Helpers Available
- `icon('name', class: '...')` — Phosphor icon helper
- `link_to ... url, class: '...' do ... end` — standard link builder
- `button_tag(type: 'button', class: '...')` — button builder
- `label_tag ... do ... end` — label builder
- `check_box_tag` — checkbox builder
- `render partial: 'name', object: value` — partial rendering
- `turbo_frame_tag 'name', target: '_top'` — Turbo frame
- `url_for(...)` — URL helpers
- `root_url`, `organizer_path` — path helpers
- `current_user`, `authenticated?`, `organizer_mode?` — auth helpers

### ERB / Herb Syntax
- Standard ERB: `<%= %>` (output), `<% %>` (logic), `<%# %>` (comment)
- Herb supports JSX-like syntax alongside standard ERB
- Multiline class strings use heredoc-style quoting:
  ```erb
  class: "
    p-2 text-gray-600
    hover:text-white
    dark:hover:bg-gray-700
  "
  ```
- Block helpers for complex markup:
  ```erb
  <%= link_to path do %>
    Content here
  <% end %>
  ```

### Breadcrumb Pattern
```erb
<%= content_for :sub_navigation do %>
  <nav class="flex mb-5" aria-label="Breadcrumb">
    <ol class="inline-flex items-center space-x-1">
      <li><%= link_to root_url, class: '...' do %>Home<% end %></li>
      <li><%= link_to [:organizer, :resources], class: '...' do %>Resources<% end %></li>
      <li><span class="ml-1 text-gray-400" aria-current="page">Current</span></li>
    </ol>
  </nav>
<% end %>
```

## Key Files
- `app/views/layouts/application.html.erb` — Main layout
- `app/views/layouts/modal.html.erb` — Modal layout
- `app/views/organizer/tournaments/show.html.erb` — Example with breadcrumb
- `app/views/events/index.html.erb` — Simple view example
