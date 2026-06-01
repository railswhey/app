<p align="center">
<small>
<code>MENU:</code> <a href="/README.md">README</a> | <a href="/docs/governance/MANIFESTO.md">Manifesto</a> | <strong>Constitution</strong>
</small>
</p>

# CONSTITUTION

> The rules of engagement for this project. Read this before contributing.

---

## What this project is

A task management application built with Ruby on Rails (Ruby 4, Rails 8). Two interfaces — a server-rendered web app and a JSON REST API — share the same domain, the same database, the same models.

But the app is not the point. The app is the vehicle.

**The point is to prove that well-organized MVC scales further than most people expect — without service objects, without hexagonal architecture, without leaving the Rails Way.**

---

## Principle 1: Test behavior, not structure

There are no controller tests. The model test files exist but are empty stubs. This is intentional.

The entire test strategy is built on **integration tests** that exercise the application through its HTTP boundaries. They test what the application *does*, not how it is organized internally. The project's thesis requires the freedom to restructure at any time — integration tests grant that freedom; unit tests punish it.

**The test suite is a behavioral contract. It encodes what the application promises to its users. Everything else is an implementation detail.**

### What the tests assert on

| Layer | What is tested |
|-------|---------------|
| **Web (Minitest)** | HTTP status codes, redirects, flash messages, rendered HTML content (`assert_select`) |
| **API (Minitest)** | HTTP status codes, JSON response envelope (`{status, type, data}`) |
| **E2E Web (Playwright)** | Full browser flows: form submission, navigation, visible text, URL transitions |
| **E2E API (curl + jq)** | HTTP status codes, JSON response structure against a live server |

### What the tests do NOT assert on

- Controller class names or file locations
- Model namespaces or internal method names
- View template paths or partial organization
- How many classes or modules exist
- Whether logic lives in a controller, model, concern, or PORO

---

## Principle 2: Decouple tests from routes

Routes are the most volatile structural detail in a Rails application. The solution is a **route abstraction layer** — tests never call route helpers directly, they call semantic aliases:

```ruby
# test/test_helper.rb — one method per semantic route
class WebAdapter
  def user__sessions_url = test.session_users_url
end
```

The double-underscore (`__`) signals "this is a semantic alias, not a Rails route helper." The same pattern is implemented in TypeScript (`e2e/web/tests/support/routes.ts`) and bash (`e2e/api/support/routes.sh`).

**Three languages, three test runners, one principle: routes are defined once and referenced by name everywhere else.** If a test file needs editing after a route change, the abstraction layer is leaking. Fix the layer, not the tests.

---

## Principle 3: The response contract is explicit

The API follows a strict response envelope enforced by every API test:

```
Success (2xx): { "status": "success", "type": "object|array", "data": { ... } }
Failure (4xx): { "status": "failure", "type": "object", "data": { "message": "...", "details": { ... } } }
Error   (5xx): { "status": "error",   "type": "object", "data": { "message": "..." } }
```

`assert_response_with_success` and `assert_response_with_failure` verify the shape on every test. The web interface has its own implicit contract: flash messages in `.notice-text`, validation errors on `:unprocessable_entity`, successful creates redirect to the resource index.

---

## Principle 4: Stay on the Rails

No service objects. No interactors. No command pattern. No hexagonal ports and adapters.

The tools are: controllers, models, concerns, callbacks, `Current`, scopes, validations, `has_secure_password`, `generates_token_for`, `before_action`, `respond_to`. Standard Rails.

This is not a limitation — it is the thesis. When you need to add a feature, reach for the simplest Rails mechanism that fits.

---

## Principle 5: Documentation proves the thesis

The README is not a feature catalog. It is the first argument for the project's thesis.

The architecture section belongs in the README because it *is* the evidence — not a description of the codebase, but proof that the Rails Way scales. Documentation has a single source of truth: never maintain a parallel static copy of information that lives authoritatively elsewhere.

For the documentation hierarchy and operational rules, see [docs/guidelines/documentation.md](../guidelines/documentation.md).

---

## Principle 6: Views mirror controllers

When a design restructures controllers, the view layer follows the same structure. Controllers and views move in lockstep. If controllers gain namespaces, views gain matching directories. If controllers split web/API, views split web/API.

This is not optional. Do not leave the view layer implicit.

---

## Principle 7: Branches argue a thesis

Each branch names a design concept, not an implementation structure. The branch README is a narrative argument: state the concept, show the evidence, name the weakness, point forward. Each includes an honest assessment of its structural impact on coding agents.

Each branch README ties its outcome back to the Constitution's principles. If a restructuring passes the test suite without changing a single assertion, the README names Principle 1. If a branch achieves domain isolation using only standard Rails tools, it claims that victory for Principle 4.

Quality is tracked with a verifiable metric (Rubycritic score). For formatting conventions, see [docs/guidelines/branch-conventions.md](../guidelines/branch-conventions.md).

---

## Principle 8: Design decisions are traceable

Design documents reference the source files that informed them. Future sessions and agents can trace any decision back to its original context without guessing.

For the references section format, see [docs/guidelines/design-documents.md](../guidelines/design-documents.md).

---

## Principle 9: Agent impact is measured, not explained

Coding agents operate under a hard constraint: context windows are finite. Every token consumed has a cost — in money, in latency, and in reasoning quality. When an agent loads a 277-line fat controller to fix a 10-line concern, it pays a 27× overhead in context.

This principle is stated once, here. Branch READMEs do not repeat it.

Each branch README includes an **agent's view** section that reports the delta — how the architectural change affected agent efficiency in concrete numbers. The format is metric-first: state the reduction, name the mechanism, show the file counts. No preamble. No re-explanation of why tokens matter.

---

## How to contribute

### Restructuring the implementation

This is explicitly encouraged. Rename controllers, reorganize namespaces, move logic between layers, extract or inline concerns. The only rule: **the behavioral contract must hold.**

### New routes

Add aliases to all three abstraction layers — never hardcode a URL path in a test file:

- `test/test_helper.rb` (`WebAdapter` / `APIV1Adapter`)
- `e2e/web/tests/support/routes.ts`
- `e2e/api/support/routes.sh`

### What will break the contract

A change fails the test suite if it:

1. Changes HTTP status codes for existing endpoints
2. Changes redirect targets after form submissions
3. Changes the API response envelope shape
4. Removes or alters user-visible flash messages
5. Removes a behavior that users depend on
6. Breaks the route abstraction (alias points to a nonexistent helper)

### What will NOT break the contract

A change is safe if it only affects what the tests do NOT assert on — see the list under [Principle 1](#principle-1-test-behavior-not-structure).

### The `member!` convention

Tests call `member!(user)` instead of `user` to signal membership context. Today it is the identity function. Use it wherever a test accesses user-scoped resources. If multi-tenancy becomes more complex, `member!` is the single point where that complexity gets absorbed. Do not remove it. Do not bypass it.

---

## Origin

V1 ([rails-way-app](https://github.com/solid-process/rails-way-app)) asked: *what happens when you systematically improve a Rails app's design without leaving the Rails Way?*

The answer was 18 branches — from one-controller-per-model to orthogonal domain objects — with a code quality score rising from 89 to 96. The most transferable artifact was not any particular branch's architecture. It was the test suite — a behavioral contract that validated every variant.

V2 carries this forward. The application is richer. The stack is modern. The principle is the same: **test the contract, free the implementation.**

---

<p align="center">
<small>
The <a href="/docs/governance/MANIFESTO.md">Manifesto</a> is what this project believes. The <a href="/docs/governance/CONSTITUTION.md">Constitution</a> defines the principles we follow.
</small>
</p>
