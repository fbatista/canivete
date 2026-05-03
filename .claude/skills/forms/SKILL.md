---
name: forms
description: Build Rails forms with Tailwind CSS, Turbo integration, and strong params validation
license: MIT
---

## What I do
- Build forms using Rails form helpers (form_with, form_for)
- Style forms with Tailwind CSS and Flowbite components
- Handle form validation errors with Turbo/partial re-renders
- Configure strong params in controllers with `params.expect`

## When to use me
- Creating new resource forms
- Modifying existing forms
- Adding form validation or error display
- Building nested forms

## Project Conventions

### Form Builder Pattern
```erb
<%= form_with model: [:organizer, @resource], class: "space-y-4" do |f| %>
  <% if @resource.errors.any? %>
    <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
      <ul>
        <% @resource.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div>
    <%= f.label :name, class: "block text-sm font-medium text-gray-700" %>
    <%= f.text_field :name, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
  </div>

  <div>
    <%= f.submit "Save", class: "bg-blue-700 text-white px-4 py-2 rounded-lg hover:bg-blue-800" %>
  </div>
<% end %>
```

### Strong Params
- Rails 8: `params.expect(model: [:field1, :field2])`
- Array of permitted fields, not require+permit chain
- Example: `params.expect(tournament: %i[name state start_time end_time])`

### Form Validation Flow
1. Controller: `@resource.attributes = params` → fails validation
2. Controller: `render :edit, status: :unprocessable_entity`
3. View: errors hash populated, form re-renders with error messages
4. Turbo: handles the 422 response, replaces the form partial

### Field Types
- Text fields: `f.text_field :name`
- Text areas: `f.text_area :description`
- Date/time: `f.datetime_field :start_time`
- Selects: `f.select :state, options_for_select(...)`
- Checkboxes: `f.check_box :accepted_terms`
- File upload: `f.file_field :cover` (for ActiveStorage)
- Hidden: `f.hidden_field :field`

### Turbo-Integrated Forms
- Forms in Turbo frames: `form_with` with `data: { turbo_frame: "frame_id" }`
- Turbo-preflighted submissions: automatic for Turbo-enabled forms
- Submit via Turbo method: `data: { "turbo-method": :delete }`
- Modal forms: wrapped in `<turbo-frame id="modal">` with `target: "_top"`

### Common Form Patterns
- **Terms acceptance**: `f.check_box :accepted_terms` + validation in model
- **Cover photo upload**: `f.file_field :cover` + `has_one_attached :cover`
- **Nested attributes**: For related records in a single form
- **Organizer context**: `merge(event_organizer: current_organizer)` in controller

## Key Files
- `app/views/registrations/new.html.erb` — User registration form
- `app/views/passwords/new.html.erb` — Password reset form
- `app/controllers/organizer/tournaments_controller.rb` — Strong params with `params.expect`
