<p align="center">
<small>
<code>MENU:</code> <a href="/README.md">README</a> | <strong>E2E Tests</strong> | <a href="/e2e/web/README.md">Web</a> | <a href="/e2e/api/README.md">API</a>
</small>
</p>

# E2E Tests

End-to-end tests that exercise the application against a running server. Two independent suites cover the two interfaces:

| Suite | Stack | What it tests | Guide |
|-------|-------|---------------|-------|
| **[Web](./web/README.md)** | Playwright (TypeScript) | Full browser flows — forms, navigation, visible text, URLs | `mise run e2e:web` (fast) / `mise run e2e:web:full` |
| **[API](./api/README.md)** | curl + jq (Bash) | JSON REST API — status codes, response envelope contract | `mise run e2e:api` |

Run both at once:

```bash
mise run e2e:test
```

Both suites require a running server (`bin/dev`). See each suite's README for details.
