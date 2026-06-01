<p align="center">
<small>
<code>MENU:</code> <a href="/README.md">README</a> | <a href="/docs/03-THE-GRADIENT.md">The Gradient</a> | <strong>Installation</strong> | <a href="/docs/01-FEATURES.md">Features &amp; Screenshots</a> | <a href="/docs/02-TESTING.md">Testing</a> | <a href="/docs/governance/MANIFESTO.md">Manifesto</a>
</small>
</p>

# Installation <!-- omit in toc -->

Detailed instructions to set up and run the application locally.

**Table of contents:**

- [System dependencies](#system-dependencies)
- [Setup](#setup)
- [Running the application](#running-the-application)
- [Demo accounts](#demo-accounts)
- [E2E test setup](#e2e-test-setup)
- [Running the test suite](#running-the-test-suite)
- [App statistics](#app-statistics)

## System dependencies

This project uses [mise](https://mise.jdx.dev/) to manage all runtime dependencies:

| Tool | Version | Purpose |
|------|---------|---------|
| Ruby | 4.0.1 | Application runtime |
| Node | 22 | E2E tests (Playwright) |
| Mailpit | 1.29.2 | Local email server for development |

> **Install mise:** follow the [mise installation guide](https://mise.jdx.dev/getting-started.html), then run `mise install` in the project root.

## Setup

```sh
git clone git@github.com:railswhey/app.git -b main rwa && cd rwa
mise install                 # Ruby 4.0.1 + Node 22 + Mailpit 1.29.2
bin/setup                    # bundle install, db:prepare, starts dev server
```

Use `mise run dev:setup` to set up without starting the server.

Use `mise run dev:reset` to drop and re-create the database from scratch.

## Running the application

```sh
bin/dev                      # Rails :3000 + Mailpit :8025 (via foreman)

# or

mise run dev:start           # same as bin/dev
```

Or start components individually:

```sh
bin/rails server             # Rails only (port 3000)
mise run dev:mailpit          # Mailpit only (SMTP :1025, Web UI :8025)
```

**URLs:**

| Service | URL |
|---------|-----|
| App | http://localhost:3000 |
| Mailpit UI | http://localhost:8025 |
| API docs | http://localhost:3000/api/docs |

## Demo accounts

After `bin/rails db:seed` (included in `mise run dev:setup`), two users are available for login:

| User | Email | Password |
|------|-------|----------|
| bob | bob@email.com | 123123123 |
| alice | alice@email.com | 123123123 |

Bob has several task lists with seed data. Alice has 2 unread notifications (a transfer request and an invitation from Bob).

## E2E test setup

```sh
mise run e2e:install         # npm install + Playwright Chromium
```

This installs Node dependencies and the Chromium browser used by Playwright. See the [E2E testing guide](../e2e/README.md) for how each suite works.

## Running the test suite

**Full CI pipeline** (recommended):

```sh
mise run dev:ci              # setup + RuboCop + Brakeman + bundler-audit + tests

# or

bin/ci
```

**Individual commands:**

| Command | What it runs |
|---------|-------------|
| `bin/rails test` | Integration tests (Minitest) |
| `mise run e2e:web` | Playwright navigation smoke test (fast, ~15s) |
| `mise run e2e:web:full` | All Playwright specs (~5min) |
| `mise run e2e:api` | curl + jq smoke tests (requires running server) |
| `mise run e2e:test` | All E2E (e2e:web fast + e2e:api) |

> See [Testing](./02_TESTING.md) for running subsets, CI pipeline details, and E2E deep dives.

## App statistics

```sh
bin/rails stats
```
