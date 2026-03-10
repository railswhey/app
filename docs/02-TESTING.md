<p align="center">
<small>
<code>MENU:</code> <a href="/README.md">README</a> | <a href="/docs/00-INSTALLATION.md">Installation</a> | <a href="/docs/01-FEATURES.md">Features &amp; Screenshots</a> | <strong>Testing</strong> | <a href="/docs/governance/MANIFESTO.md">Manifesto</a>
</small>
</p>

# Testing <!-- omit in toc -->

The test strategy is built on **integration tests** — tests that exercise the application through its HTTP boundaries. There are no controller tests. Model test files exist but are empty stubs. This is intentional (see [CONSTITUTION.md](./governance/CONSTITUTION.md), Principle 1).

**Table of contents:**

- [Overview](#overview)
- [CI pipeline (`bin/ci` or `mise run dev:ci`)](#ci-pipeline-binci-or-mise-run-devci)
- [Minitest (`bin/rails test`)](#minitest-binrails-test)
  - [Running subsets](#running-subsets)
- [E2E tests](#e2e-tests)
- [Route abstraction](#route-abstraction)

## Overview

Three test layers cover the two interfaces (web + API):

| Layer | Tool | What it tests | Command |
|-------|------|---------------|---------|
| Integration | Minitest (Ruby) | HTTP status codes, redirects, flash messages, JSON envelope | `bin/rails test` |
| E2E Web | Playwright (TypeScript) | Full browser flows: forms, navigation, visible text, URLs | `mise run e2e:web` (fast) / `mise run e2e:web:full` |
| E2E API | curl + jq (Bash) | JSON REST API against a live server | `mise run e2e:api` |

Run everything:

```sh
bin/ci                       # CI pipeline (setup + lint + security + Minitest)
mise run e2e:test            # all E2E (web + API, requires running server)
```

## CI pipeline (`bin/ci` or `mise run dev:ci`)

The primary command — run after every relevant change. Steps are defined in [config/ci.rb](../config/ci.rb):

1. **Setup** — `mise run dev:setup` (full setup with DB reset)
2. **Style** — RuboCop (`mise run check:rubocop`)
3. **Security** — Brakeman + bundler-audit (`mise run check:brakeman`, `mise run check:audit`)
4. **Tests** — `bin/rails test`

E2E tests are **not** part of CI (they require a running server). Run them separately with `mise run e2e:test`.

## Minitest (`bin/rails test`)

Integration tests live under `test/integration/`, organized by interface:

```
test/integration/
├── api/v1/           # JSON API tests
│   ├── my_tasks/
│   ├── search/
│   ├── task/
│   │   ├── items/
│   │   └── lists/
│   └── users/
└── web/              # Server-rendered web tests
    ├── guest/
    ├── task/
    │   ├── items/
    │   └── list/
    └── user/
        └── settings/
```

Two helper classes in [test/test_helper.rb](../test/test_helper.rb) provide the route abstraction layer and response assertions:

- **`WebAdapter`** — web integration tests. Provides semantic route aliases (e.g. `user__sessions_url`) and flash/redirect assertions.
- **`APIV1Adapter`** — API integration tests. Same route aliases with `.json` format, plus `assert_response_with_success` and `assert_response_with_failure` for envelope validation.

### Running subsets

```sh
bin/rails test                                    # all tests
bin/rails test test/integration/web/              # all web integration tests
bin/rails test test/integration/api/              # all API integration tests
bin/rails test test/integration/web/task/items/   # specific directory
bin/rails test test/integration/web/task/items/create_test.rb      # single file
bin/rails test test/integration/web/task/items/create_test.rb:15   # single test (line number)
```

## E2E tests

Both suites require a running server (`bin/dev`). Each has its own detailed README:

- **[E2E overview](../e2e/README.md)** — index of both suites
- **[Web tests (Playwright)](../e2e/web/README.md)** — browser flows, Mailpit email testing, screenshot capture
- **[API tests (curl + jq)](../e2e/api/README.md)** — smoke tests, response logging for API docs

```sh
mise run e2e:web              # Playwright navigation smoke test (fast)
mise run e2e:web:full         # all Playwright specs
mise run e2e:api              # curl + jq smoke tests
mise run e2e:test             # e2e:web + e2e:api
```

## Route abstraction

Tests never reference Rails route helpers directly. When routes change, update these three files — no test file should need editing:

| Layer | File |
|-------|------|
| Minitest | [test/test_helper.rb](../test/test_helper.rb) (`WebAdapter` / `APIV1Adapter`) |
| E2E Web | [e2e/web/tests/support/routes.ts](../e2e/web/tests/support/routes.ts) |
| E2E API | [e2e/api/support/routes.sh](../e2e/api/support/routes.sh) |

See [CONSTITUTION.md](./governance/CONSTITUTION.md), Principle 2 for the full rationale and code examples.
