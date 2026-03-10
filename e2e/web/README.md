<p align="center">
<small>
<code>MENU:</code> <a href="/README.md">README</a> | <a href="/e2e/README.md">E2E Tests</a> | <strong>Web</strong> | <a href="/e2e/api/README.md">API</a>
</small>
</p>

# E2E Web Tests

Playwright browser tests that exercise the server-rendered web application against a **running server**. They verify full user flows — form submission, navigation, visible text, URL transitions — through a real browser (Chrome).

## Running

```bash
# Requires a running server with Mailpit (bin/dev)
mise run e2e:web                # navigation smoke test (fast, ~15s)
mise run e2e:web:full           # all specs (~5min)
npx playwright test <file>      # single spec (from e2e/web/)
```

> **Agent sessions:** if `mise` shims aren't in `$PATH`, prefix with `export PATH="$HOME/.local/share/mise/shims:$PATH"`.

## How it works

Each spec creates its own ephemeral users via the sign-up form (`uniqueUser()` generates timestamped credentials). Tests interact with the app through Playwright's semantic selectors (`getByRole`, `getByLabel`, `getByPlaceholder`) and verify outcomes by asserting on visible text, URLs, and page structure.

Email-dependent flows (password reset, invitations, transfers) use **Mailpit** — a local SMTP server running alongside `bin/dev` on port 8025. The `mailpit.ts` helper polls the Mailpit API to wait for emails, extract bodies, and find action links.

### Configuration highlights

- **Workers: 1** — tests run sequentially because the Mailpit mailbox is shared.
- **Retries:** 2 in CI, 1 locally.
- **Base URL:** `process.env.BASE_URL` or `http://localhost:3000`.
- **Browser:** Chrome desktop only.

## Directory structure

```
e2e/web/
├── package.json                 # @playwright/test + typescript
├── playwright.config.ts         # Browser, workers, retries, base URL
├── tsconfig.json
└── tests/
    ├── support/
    │   ├── routes.ts            # Route path helpers (single source of truth)
    │   ├── helpers.ts           # uniqueUser(), signUp(), signIn(), signOut(), openNav()
    │   └── mailpit.ts           # clearMailbox(), waitForEmail(), getEmailBody(), extractLink()
    ├── auth.spec.ts             # Sign up/in/out, password change/reset, account deletion
    ├── navigation.spec.ts       # Sidebar items, account switcher, logo link
    ├── task-lists.spec.ts       # CRUD, inbox protection, summary section
    ├── task-items.spec.ts       # CRUD, complete/incomplete, filters, move between lists
    ├── collaboration.spec.ts    # Invitations, cross-user visibility, permissions, account switching
    ├── transfers.spec.ts        # List ownership transfer between users
    ├── transfer-email.spec.ts   # Transfer notification email with Mailpit
    ├── comments.spec.ts         # Comments on lists and items, ownership rules
    ├── my-tasks.spec.ts         # Assigned tasks view, filters, assign/unassign
    ├── search.spec.ts           # Full-text search for lists, items, comments
    ├── notifications.spec.ts    # Notification list, mark read, unread badge
    ├── settings.spec.ts         # Account, profile, password, API token sections
    ├── guest-access.spec.ts     # API docs access, invitation/transfer pages for guests
    ├── stale-session.spec.ts    # Recovery after removal from shared account
    ├── error-pages.spec.ts      # 404, 422, 500 pages
    └── screenshots.spec.ts      # Captures docs/screenshots/*.png (not part of regression suite)
```

## Key conventions

- **Route abstraction** — specs import path helpers from `support/routes.ts` (e.g. `taskListsPath()`, `taskItemPath(listId, id)`). URLs are never hardcoded. When routes change, update `routes.ts` only (see [CONSTITUTION.md](../../docs/governance/CONSTITUTION.md), Principle 2).
- **Unique users per test** — `uniqueUser()` returns a `{ username, email, password }` with a timestamp + counter suffix, preventing collisions even across retries.
- **`signUp` / `signIn` / `signOut`** — shared helpers that fill the real forms and wait for navigation, keeping specs focused on the behavior under test.
- **Mailpit integration** — `waitForEmail()` polls until a matching message arrives (15s timeout), then `extractLink()` pulls the action URL from the HTML body. Used by password reset, invitation, and transfer specs.
- **`openNav(page)`** — opens the hamburger menu on mobile viewports (no-op on desktop), so the same specs work across screen sizes.
- **Dialog handling** — specs that trigger `turbo_confirm` dialogs register `page.on('dialog', d => d.accept())` before the action.

## Screenshots spec

`screenshots.spec.ts` is a capture tool, **not** a regression test — it is excluded from `mise run e2e:web`. It signs up a fresh user, builds realistic state, navigates through all key pages, and saves PNGs to `docs/screenshots/`. Run it manually when the UI changes:

```bash
mise run e2e:web:screenshots
```

## Adding a new spec

1. Create `tests/<feature>.spec.ts`.
2. Add any new route helpers to `support/routes.ts`.
3. Use `uniqueUser()` + `signUp()` for test isolation.
4. Use semantic selectors (`getByRole`, `getByLabel`) over CSS selectors.
5. Remember to also add the route aliases to the other two abstraction layers (`test/test_helper.rb` and `e2e/api/support/routes.sh`).
