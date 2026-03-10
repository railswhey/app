# AGENTS.md

> **Before starting ANY task, you MUST read these files (in order):**
> 1. [`MANIFESTO.md`](./docs/governance/MANIFESTO.md)
> 2. [`CONSTITUTION.md`](./docs/governance/CONSTITUTION.md)
>
> Do not skip this step. Do not assume you know their contents.

## Dev Setup

- **Full setup:** `bin/setup` — installs deps, prepares DB, starts dev server (use `--skip-server` for headless)
- **Full dev:** `bin/dev` — Rails + Mailpit via foreman (port 3000 + 8025)
- **Server only:** `bin/rails server -b 0.0.0.0 -d` — standalone, daemonized (for agent sessions)
- **Seed:** `bin/rails db:seed` (idempotent) — see [db/seeds.rb](./db/seeds.rb) for demo users and credentials

> See [Installation](./docs/00-INSTALLATION.md) for system dependencies, demo accounts, and full setup details.

## Testing

**After any relevant change, run `bin/ci`** — the full CI pipeline: setup, RuboCop, Brakeman, bundler-audit, and tests (see [config/ci.rb](./config/ci.rb)).

Individual test commands for faster feedback during development:

- `bin/rails test` — unit/integration (Minitest)
- `mise run e2e:web` — Playwright navigation smoke test (fast, ~15s)
- `mise run e2e:web:full` — all Playwright specs (~5min)
- `mise run e2e:api` — curl + jq smoke tests (requires running server)
- `mise run e2e:test` — all E2E (e2e:web fast + e2e:api)

> **Tip:** Run `mise tasks` to discover all available commands (`dev:*`, `rails:*`, `check:*`, `e2e:*`).

> See [Testing](./docs/02-TESTING.md) for running subsets, CI pipeline details, and E2E deep dives.
> See [e2e/README.md](./e2e/README.md) for detailed guides on each E2E suite.

> **Note:** If mise shims aren't in your `$PATH` (common in agent sessions), prefix with:
> `export PATH="$HOME/.local/share/mise/shims:$PATH"`

## Guidelines

- [Branch Conventions](./docs/guidelines/branch-conventions.md) — Branch naming, commit messages, README purpose/structure/style, Rubycritic, agent-impact
- [Design Documents](./docs/guidelines/design-documents.md) — References section format for `docs/plans/`
- [Documentation](./docs/guidelines/documentation.md) — Where content lives, API docs workflow, no parallel copies rule
- [Task Runner](./docs/guidelines/task-runner.md) — Mise task namespaces, adding new tasks, conventions
- [UI Patterns](./docs/guidelines/ui-patterns.md) — Detail cards, modals, sidebar, mobile rules

## Evolving Guidelines

When a session introduces a new structure, convention, or recurring pattern to the project, suggest creating or updating a guideline file in `docs/guidelines/`. Guidelines capture stable decisions so future sessions don't re-derive them. Before suggesting, verify the pattern is intentional (not a one-off) and aligns with [CONSTITUTION.md](./docs/governance/CONSTITUTION.md).
