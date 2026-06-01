<p align="center">
<small>
◂ <a href="/docs/branches/7D-shared-kernel.md">7D</a> | <a href="/docs/03-THE-GRADIENT.md"><strong>The Gradient</strong></a>
</small>
</p>

<h1 align="center" style="border-bottom: none;">
  <img src="/docs/assets/emoji-mechanical-arm.png" alt="" width="36" height="36">
  Rails Whey App
  <img src="/docs/assets/emoji-mechanical-arm-flipped.png" alt="" width="36" height="36">
</h1>

<p align="center">
  <img src="/docs/assets/logo.png" alt="Rails Whey App" width="180" height="180">
</p>

# What's Next <!-- omit in toc -->

> The gradient doesn't end at 7D. Here's where it's going.

---

Twenty-eight branches. Seven families. One codebase. From a single fat controller to fully isolated engines with separate databases — using only Rails' own tools. Every point on the gradient is valid. Every tradeoff is named honestly.

But the arc isn't over.

7D proved that Rails can enforce physical boundaries through engines and multi-database isolation. It also revealed a tension: the structural enforcement that serves teams comes at a cost to the developer navigating between them. The naming gap between `Web::Task::*` controllers and `Workspace::*` models. Tests living in the host, not the engines. A resolver that knows too much about how each engine authenticates.

These aren't flaws. They're the next chapter.

---

## Two paths forward

```mermaid
flowchart TD
    subgraph "The gradient so far"
        F6["Family 6<br><small>Naming peak</small>"]
        F7["Family 7<br><small>Structural peak</small>"]
    end

    subgraph "Path 1: Incremental (7E-7I)"
        P1["Complete engine extraction<br>+ optimize resolution<br>+ durable sagas"]
    end

    subgraph "Path 2: Self-Contained Systems (Family 8)"
        P2["Each domain becomes<br>its own engine<br>full stack per domain"]
    end

    F7 --> P1
    F7 --> P2

    style F6 fill:#4a9,stroke:#333,color:#fff
    style F7 fill:#fc9,stroke:#333
    style P1 fill:#369,stroke:#333,color:#fff
    style P2 fill:#247,stroke:#333,color:#fff
```

### Path 1: Complete what 7D started (7E-7I)

Five incremental steps that refine 7D without changing the architecture:

| Step | What it does |
|---|---|
| **7E** | Tests move to engines |
| **7F** | Resolver splits per engine |
| **7G** | Lazy resolution + session persistence |
| **7H** | `ActiveJob::Continuable` replaces custom process manager abstraction |
| **7I** | `Rails.event.notify` + compensation jobs |

Two Rails 8.1 features power the saga evolution: `ActiveJob::Continuable` (durable step-by-step job execution) for forward progress and `Rails.event.notify` (Structured Event Reporting) for event-driven compensation. No new infrastructure tables. The queue backend becomes the durability layer.

### Path 2: Self-Contained Systems (Family 8)

A different question entirely: what if each bounded context owns its **full stack** — models, controllers (web + API), views, jobs, mailers, database, and tests — in a single engine?

```mermaid
flowchart TD
    subgraph "Family 7: horizontal slicing"
        K7["Kernel<br><small>all models</small>"]
        W7["Web Engine<br><small>all web controllers</small>"]
        A7["API Engine<br><small>all API controllers</small>"]
        W7 --> K7
        A7 --> K7
    end

    subgraph "Family 8: Self-Contained Systems"
        UE["User Engine<br><small>models + web + api<br>+ jobs + tests + DB</small>"]
        AE["Account Engine<br><small>models + web + api<br>+ jobs + tests + DB</small>"]
        WE["Workspace Engine<br><small>models + web + api<br>+ jobs + tests + DB</small>"]
        UE -. "events" .- AE
        AE -. "events" .- WE
        WE -. "events" .- UE
    end

    style K7 fill:#f5f5f5,stroke:#333
    style W7 fill:#e8f4fd,stroke:#333
    style A7 fill:#e8fde8,stroke:#333
    style UE fill:#e8f4fd,stroke:#333
    style AE fill:#e8fde8,stroke:#333
    style WE fill:#fff3e0,stroke:#333
```

Left: 7D slices by delivery mechanism — domain is scattered across three locations. Right: Family 8 slices by domain — everything for a bounded context lives in one engine.

The naming gap disappears. `Workspace::Task` model and `Workspace::Web::Task::ItemsController` share the same engine and namespace. One grep finds everything.

The complexity moves to coordination. Engines communicate through `Rails.event.notify` — Structured Event Reporting from Rails 8.1. Identity propagates via events: when a user registers, the User engine emits an event and each other engine creates its own local copy of the identity (like `Account::Person` and `Workspace::Member` already do in 7A). No engine ever queries another engine's database.

A minimal, acyclic shared kernel provides two domain-agnostic primitives: `AccessToken` (token parsing for API auth) and `DomainEvent` (sync/async event dispatch, with Solid Queue as a transactional outbox). A Design System engine provides UI consistency. Everything else lives in the domain engines.

This is a complete rewrite — not an incremental step. It's for teams whose codebase, team size, or deployment requirements justify the structural investment.

---

## The road ahead

The gradient exists to prove one thing: **the Rails Way has more room in it than most people think.**

The design decisions get harder — bounded contexts, saga compensation, engine extraction, event-driven coordination — but the tools stay the same. Ruby modules. Rails engines. Active Job. Active Record. The framework adapts.

The question was never whether Rails can handle sophisticated architecture. It always was: **how much architecture does your codebase actually need?**

The gradient doesn't prescribe an answer. It demonstrates the range. Every point is a valid choice for a real team shipping real software.

The next chapters will build it. 🦾
