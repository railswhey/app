# Task Runner

All operator commands are exposed as mise tasks and discoverable via `mise tasks`. Tasks use namespaced names (`namespace:task`) for grouping.

## Namespaces

| Namespace | Purpose | Examples |
|-----------|---------|----------|
| `check:` | Code quality and security tools | `check:rubocop`, `check:brakeman`, `check:audit` |
| `dev:` | Development workflow — servers, setup, CI | `dev:start`, `dev:setup`, `dev:ci` |
| `e2e:` | End-to-end tests (Playwright + curl) | `e2e:web`, `e2e:web:full`, `e2e:web:screenshots`, `e2e:api`, `e2e:test` |
| `rails:` | Direct `bin/rails` wrappers | `rails:server`, `rails:test` |

## Adding a new task

1. Choose the correct namespace based on the table above. If none fits, propose a new namespace — do not use top-level (un-namespaced) task names.
2. Define the task in `mise.toml` under the appropriate section comment.
3. Keep descriptions short (one line), starting with a verb.
4. If the task wraps a `bin/` script, delegate to it — do not duplicate the script's logic in `run`.

## Rails is first-class

This is a Rails project. `bin/rails` commands are the primary interface in documentation and agent instructions. Mise tasks (`rails:*`) exist for discoverability in `mise tasks` output, but docs should reference `bin/rails` directly when describing Rails commands.

## Flag passthrough

Mise passes extra CLI arguments to the underlying command. Use `--` to separate mise args from task args:

```sh
mise run dev:setup -- --skip-server
mise run dev:setup -- --reset
```

## Conventions

- **Two levels by default** — `namespace:task` is the standard. The `e2e:web:*` sub-namespace (`e2e:web:full`, `e2e:web:screenshots`) is the established exception — it groups execution modes for the same suite. Do not introduce new three-level names without a clear grouping rationale.
- **Section comments** in `mise.toml` separate namespace groups (e.g., `# ── dev: development workflow ──`).
- **No orphan tasks** — every task belongs to a namespace. The only exception is if a future need demands a truly standalone command.
