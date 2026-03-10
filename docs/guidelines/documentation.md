# Documentation

## No parallel static copies of live docs

If information lives authoritatively in one place, do not copy it into another file that will be maintained manually. It will drift.

Specifically:
- API docs live in an endpoint as HTML + markdown, not in a static file.

## Navigation menus

Every documentation file includes a `<p align="center"><small>` navigation menu at the top using pure HTML. The current page is `<strong>` (bold); all others are `<a href>` links. All paths are repo-root-absolute (start with `/`), so every file in a menu group uses the exact same HTML — only the `<strong>` item differs.

There are three menu groups:

**Main docs** (`README.md` + `docs/`):

```html
<p align="center">
<small>
<code>MENU:</code> <a href="/README.md">README</a> | <a href="/docs/00-INSTALLATION.md">Installation</a> | <a href="/docs/01-FEATURES.md">Features &amp; Screenshots</a> | <a href="/docs/02-TESTING.md">Testing</a> | <a href="/docs/governance/MANIFESTO.md">Manifesto</a>
</small>
</p>
```

**Governance docs** (`docs/governance/`):

```html
<p align="center">
<small>
<code>MENU:</code> <a href="/README.md">README</a> | <a href="/docs/governance/MANIFESTO.md">Manifesto</a> | <a href="/docs/governance/CONSTITUTION.md">Constitution</a>
</small>
</p>
```

**E2E docs** (`e2e/`, `e2e/web/`, `e2e/api/`):

```html
<p align="center">
<small>
<code>MENU:</code> <a href="/README.md">README</a> | <a href="/e2e/README.md">E2E Tests</a> | <a href="/e2e/web/README.md">Web</a> | <a href="/e2e/api/README.md">API</a>
</small>
</p>
```

Rules:
- Replace the current page's `<a href>` with `<strong>` (bold, no link).
- When adding a new doc to a group, add it to the menu in **every** file in that group.
- The E2E and governance menus include a link back to the main `README.md` for discoverability.

## Documentation hierarchy

| Location | Purpose | Owner |
|----------|---------|-------|
| `AGENTS.md` | Agent cheat sheet — quick-reference commands + links | Update when commands or guideline files change |
| `docs/governance/MANIFESTO.md` | Why the project is named what it's named; taste philosophy | Update when identity/philosophy evolves |
| `docs/governance/CONSTITUTION.md` | Testing philosophy, route abstraction, response contract, contribution rules, `member!` convention, project origin | Update when principles evolve |
| `README.md` | Thesis + architecture proof + quick start + testing | Always kept short; architecture section must stay |
| `docs/00-INSTALLATION.md` | Setup, running, demo accounts, E2E install | Update when setup changes |
| `docs/01-FEATURES.md` | Full feature list + UI screenshots (`docs/screenshots/*.png`) | Update when features are added; refresh screenshots with `mise run e2e:web:screenshots` |
| `docs/02-TESTING.md` | All test commands (CI, Minitest, E2E), test layers, running subsets, route abstraction quick-reference | Update when test infrastructure changes |
| API docs source files | Canonical API reference, rendered live in-app | Update alongside endpoint changes |
| `docs/guidelines/branch-conventions.md` | Branch naming, README purpose, README structure/style, Rubycritic workflow, agent-impact formatting | Update when branch conventions evolve |
| `docs/guidelines/design-documents.md` | Design doc references section format | Update when design doc conventions evolve |
| `docs/guidelines/documentation.md` | Doc hierarchy, menu rules, API doc workflow, screenshot workflow, consistency review | Update when doc structure changes |
| `docs/guidelines/task-runner.md` | Mise task namespaces, adding new tasks, conventions | Update when task structure changes |
| `docs/guidelines/ui-patterns.md` | UI component rules, modals, sidebar, mobile | Update when UI patterns change |
| `e2e/README.md` | E2E suite index | Update when E2E structure changes |
| `e2e/web/README.md` | Playwright suite internals, conventions, adding specs | Update when Playwright conventions change |
| `e2e/api/README.md` | curl+jq suite internals, API log workflow, adding endpoint tests | Update when API test conventions change |

## Updating API docs

The API docs are rendered from markdown source files at runtime — no build step, changes reflect immediately.

The pattern has two parts:
- **Content** lives in `app/views/api_docs/<section>.html.md`, one file per section. Edit the file for the relevant section.
- **Registration** lives in `APIDocsController::SECTIONS`. Adding a new section means adding it to that array and creating the matching markdown file.

Use `<%= request.base_url %>` in curl examples — the `.html.md` templates are processed as ERB before markdown rendering, so the expression is evaluated server-side and produces the correct host in any environment.

### Using the e2e API log as a reference

Running `mise run e2e:api` (requires a running server) exercises every endpoint and writes real request/response pairs to `tmp/e2e-api-logs.md`. Use this log to:

- Verify actual JSON shapes before writing example response blocks in the docs.
- Check that a new or changed endpoint returns the envelope (`status`, `type`, `data`) you expect.
- Confirm 2xx/4xx status codes match what the docs claim.

The log is overwritten on each run, so it always reflects the current server state. Do not commit it.

### Verification

When done, run the API docs integration tests to confirm nothing broke.

## Updating screenshots

Screenshots in `docs/01-FEATURES.md` are captured automatically by a Playwright spec. Do not edit the PNG files by hand.

To refresh:

```
mise run e2e:web:screenshots
```

This runs `e2e/web/tests/screenshots.spec.ts`, which signs up a fresh user, builds realistic state, navigates through all key pages, and saves PNGs to `docs/screenshots/`. Requires `mise run dev:start` to be running.

The spec is intentionally excluded from `mise run e2e:web` (the regression suite) — it is a capture tool, not a test. Run it whenever the UI changes or new pages are added. Commit the updated PNGs.

## Consistency review

> Reusable checklist for auditing documentation structure. Run this periodically or after significant doc changes.

### Files to read

**Root:**
- `README.md`
- `AGENTS.md`

**docs/:**
- `docs/*.md`
- `docs/guidelines/*.md`
- `docs/governance/*.md`

**E2E:**
- `e2e/README.md`
- `e2e/web/README.md`
- `e2e/api/README.md`

### What to check

1. **Overlaps** — Is the same content (commands, explanations, tables) duplicated in full across multiple files? Brief mentions are fine; full duplicated explanations are not.
2. **Progressive disclosure links** — Does every file that mentions a topic briefly include a link to the authoritative source for the full treatment?
3. **Content flow** — Does each doc add unique depth without forcing unnecessary jumps? Readers (human or agent) should find useful quick references without chasing through 3 docs.
4. **Navigation menus** — Are `<small>` menus present, consistent, with the current page **bold** and relative paths correct?
5. **Hierarchy table** — Does the Documentation hierarchy table above accurately describe what each file owns?

### Design principles

These are non-negotiable:

- **Brief mention + link = good.** Every doc can mention a command or concept. Quick references are valuable — don't make readers jump to another doc for basic info.
- **Full explanation in one place only.** The dedicated doc owns the complete treatment (pipeline steps, directory structure, running subsets, code examples). Other docs provide brief references and link there.
- **Each file has a distinct purpose.** No two files should be the authoritative source for the same topic.
- **Progressive disclosure.** Each level of documentation depth adds new information. Shallow docs (README) give the overview + links. Deep docs (TESTING, CONSTITUTION, E2E READMEs) give the full treatment.

### Self-update

If you discover documentation files that are not listed in the **Documentation hierarchy** table above, update this file as part of your plan:

1. Add the new file to the table with its authoritative purpose.
2. Include the table update in your **Changes per file** output so it gets applied alongside everything else.

This keeps the hierarchy accurate for the next run.

### Expected output

Produce a plan with:

1. **Findings** — List each issue found (overlap, missing link, stale hierarchy entry, broken menu, **new docs not in the hierarchy table**)
2. **Changes per file** — For each file that needs editing, specify what to add, remove, or modify
3. **Progressive disclosure flow** — A diagram showing what each level of docs provides and where it links
4. **Verification checklist** — How to confirm the changes are correct (search for specific strings, check menus, etc.)
