<p align="center">
<small>
<code>MENU:</code> <a href="/README.md">README</a> | <a href="/e2e/README.md">E2E Tests</a> | <a href="/e2e/web/README.md">Web</a> | <strong>API</strong>
</small>
</p>

# E2E API Smoke Tests

Bash + curl + jq smoke tests that exercise the JSON REST API against a **running server**. They verify HTTP status codes and the response envelope contract (`{status, type, data}` for success, `{status, message, details}` for errors) — the same contract enforced by the Minitest integration suite.

## Running

```bash
# Requires a running server (e.g. bin/dev or bin/rails server)
mise run e2e:api              # default: http://localhost:3000
mise run e2e:api BASE_URL     # custom host
```

> **Agent sessions:** if `mise` shims aren't in `$PATH`, prefix with `export PATH="$HOME/.local/share/mise/shims:$PATH"`.

## How it works

The orchestrator (`run`) does the following:

1. **Setup** — creates two ephemeral users (A and B) via `bin/rails runner` and exports their API tokens.
2. **Execute** — sources each `endpoints/NN_*.sh` file in order. Files share state (tokens, IDs) through exported variables.
3. **Teardown** — deletes both test users from the database.
4. **Summary** — prints pass/fail counts and exits non-zero on any failure.

## API call log (`tmp/e2e-api-logs.md`)

Every run writes a markdown log to `tmp/e2e-api-logs.md` containing every request/response pair — method, URL, status code, request body, and pretty-printed JSON response. The file is overwritten on each run and should never be committed.

This log is the primary reference when updating the in-app API documentation endpoint. Use it to:

- **Verify JSON shapes** — copy real response bodies into doc examples instead of writing them by hand.
- **Confirm status codes** — check that the docs claim the same 2xx/4xx codes the server actually returns.
- **Validate the envelope** — ensure every endpoint follows the `{status, type, data}` / `{status, message, details}` contract.
- **Spot regressions** — after changing an endpoint, re-run the suite and diff the log to see exactly what changed in the response.

Workflow: change an endpoint → run `mise run e2e:api` → inspect `tmp/e2e-api-logs.md` → update the corresponding `app/views/` API doc file with accurate examples.

## Directory structure

```
e2e/api/
├── run                          # Orchestrator: setup → tests → teardown
├── support/
│   ├── routes.sh                # Route path helpers (single source of truth)
│   └── helpers.sh               # curl wrappers, assertions, colored output
└── endpoints/
    ├── 00_authentication.sh     # 401 for missing/invalid tokens
    ├── 01_task_lists.sh         # CRUD + inbox protection
    ├── 02_task_items.sh         # CRUD, complete/incomplete, move
    ├── 03_my_tasks.sh           # Cross-list task view
    ├── 04_search.sh             # Full-text search
    ├── 05_memberships.sh        # Account memberships
    ├── 06_invitations.sh        # Invite flow (create, accept, reject)
    ├── 07_users.sh              # Registration, session, profile, password
    └── 08_transfers.sh          # Task list ownership transfer
```

## Key conventions

- **Route abstraction** — endpoint scripts call helpers from `support/routes.sh` (e.g. `task_lists_path`, `task_item_path`). URLs are never hardcoded. When routes change, update `routes.sh` only (see [CONSTITUTION.md](../../docs/governance/CONSTITUTION.md), Principle 2).
- **Assertions** — `helpers.sh` provides `assert_status`, `assert_json_field`, `assert_json_not_null`, `assert_json_null`, `assert_success_envelope`, and `assert_failure_envelope`. All output colored PASS/FAIL lines and increment shared counters.
- **Two-user setup** — `TOKEN_A` / `TOKEN_B` (with `TOKEN` defaulting to A) enable multi-user scenarios such as invitations and transfers.
- **Ordered execution** — files are numbered `00_`–`08_` and run sequentially. Later files may depend on state (e.g. `INBOX_ID`) exported by earlier ones.

## Adding a new endpoint test

1. Create `endpoints/NN_<resource>.sh` with the next available number.
2. Add any new route helpers to `support/routes.sh`.
3. Use the curl wrappers (`api_get`, `api_post`, `api_put`, `api_patch`, `api_delete`) and assertion helpers from `helpers.sh`.
4. Export any IDs needed by later files.
5. Remember to also add the route aliases to the other two abstraction layers (`test/test_helper.rb` and `e2e/web/tests/support/routes.ts`).
