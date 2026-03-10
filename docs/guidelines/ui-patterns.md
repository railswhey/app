# UI Patterns

## Detail Cards

All show/detail views **must** use the `.detail-card` component — never raw `<table>` or loose `<dl>`:

```erb
<div class="detail-card">
  <div class="detail-field">
    <span class="detail-label">Label</span>
    <span class="detail-value">Value</span>
  </div>
  ...
</div>
```

- Hide empty/nil fields — don't show rows with blank values
- Format dates with `strftime("%b %d, %Y at %H:%M")` — never raw UTC timestamps
- Use chips (`.chip`, `.chip-success`, `.chip-neutral`) for status fields
- Action buttons go **above** the detail card in a `.action-group` div

## Modals

Use native `<dialog>` + Stimulus `modal_controller.js`:

```erb
<dialog id="my-modal" data-controller="modal" data-action="click->modal#backdropClose">
  <div class="modal-header">
    <h3>Title</h3>
    <button class="modal-close" data-action="modal#close">✕</button>
  </div>
  <div class="modal-body">
    ...
  </div>
</dialog>
```

- Never place `<dialog>` inside `<table>` elements — browsers mangle forms inside tables
- For destructive/mutating actions inside modals, use `link_to` + `data-turbo-method` (not `button_to`)
- `.modal-subtitle` for contextual descriptions

## Sidebar Navigation

- **One sidebar for the entire app** — `shared/tasks/_header`
- Settings pages use the same sidebar (not a separate settings nav)
- Breadcrumbs handle sub-navigation within settings

## Mobile

- Drawer sidebar slides from left (not push-down)
- `.nav-backdrop` overlay dismisses on tap
- iOS Safari: **never** use `link_to + data-turbo-method + data-turbo-confirm` — use `button_to` instead
