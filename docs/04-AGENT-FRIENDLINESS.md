# Agent-Friendliness Review <!-- omit in toc -->

- [What this report evaluates](#what-this-report-evaluates)
- [Summary](#summary)
- [Evaluation Criteria](#evaluation-criteria)
- [Family Analysis](#family-analysis)
  - [Family 1: Controller Basics (1A-1B)](#family-1-controller-basics-1a-1b)
  - [Family 2: REST Discipline (2A-2B)](#family-2-rest-discipline-2a-2b)
  - [Family 3: Namespacing \& Structure (3A-3G)](#family-3-namespacing--structure-3a-3g)
  - [Family 4: Entry Points (4A-4B)](#family-4-entry-points-4a-4b)
  - [Family 5: Model Patterns (5A-5D)](#family-5-model-patterns-5a-5d)
  - [Family 6: Domain Objects (6A-6G)](#family-6-domain-objects-6a-6g)
  - [Family 7: Domain Architecture (7A-7D)](#family-7-domain-architecture-7a-7d)
- [Cross-Family Rankings](#cross-family-rankings)
  - [Inflection Points](#inflection-points)
  - [Score progression through the gradient](#score-progression-through-the-gradient)
- [Guidance Requirements](#guidance-requirements)
  - [Why Family 6 needs almost no guidance](#why-family-6-needs-almost-no-guidance)
  - [Where guidance bridges the orthogonality gap: Family 7](#where-guidance-bridges-the-orthogonality-gap-family-7)
  - [The guidance spectrum](#the-guidance-spectrum)
- [Conclusion](#conclusion)
  - [The architectural sweet spot](#the-architectural-sweet-spot)
  - [What makes code agent-friendly](#what-makes-code-agent-friendly)
  - [The practical takeaway](#the-practical-takeaway)

## What this report evaluates

This report examines 28 branches of a Rails task-management application (accounts, users, task lists, task items, comments, invitations, notifications, transfers). Each branch represents the same feature set built with a different architectural approach. The branches are organized into 7 families and form a progressive gradient -- from a single fat controller (1A) through REST discipline, namespacing, API separation, model patterns, domain objects, and finally domain architecture with bounded contexts and engine extraction.

Each branch builds on concepts from the families before it. The gradient exists to prove that **you do not need to leave Rails or Ruby** to achieve sophisticated architecture -- the framework adapts from the simplest CRUD to bounded contexts with separate databases and mountable engines.

The question driving this review: **which level of architectural sophistication makes a codebase easiest for a coding agent to navigate and modify?**

## Summary

The 28-branch gradient reveals a clear architectural sweet spot for coding agents: **branches 5C through 6G** (unified vocabulary through named orchestrations) deliver the highest agent-friendliness, peaking at **6G (24/25)** and **5D (23/25)**. The key insight: **naming is the highest-leverage investment for agent-friendliness.** Unified vocabulary (5C), declared authority (6E), and named orchestrations (6G) each produce step-change improvements, while structural reorganizations without naming changes (3A-3C, 6F) plateau.

Family 7 demonstrates that Rails and Ruby can take you all the way to bounded contexts, separate databases, and engine extraction -- without leaving the framework. Its domain layer inherits Family 6's self-revealing patterns; the added complexity lives in the representation layer and infrastructure. The orthogonality between domain naming (`Workspace::*`) and presentation naming (`Web::Task::*`) is a deliberate decoupling that gives the view layer freedom at the cost of an extra mapping step for agents. Complexity is not bad when justified -- for this codebase size it exceeds what is needed, but the gradient exists to prove the framework's full capabilities.

## Evaluation Criteria

Every branch was evaluated on 5 dimensions, scored 1-5:

| Dimension | What it measures | How it's measured |
|---|---|---|
| **Context window cost** | Files and lines an agent must load for a targeted change | Count files/lines for "fix a bug in task completion" |
| **Discoverability** | How quickly an agent finds the right file | Search steps from behavior description to source file |
| **Isolation** | Whether a change requires understanding unrelated code | Files sharing state, concerns, or coupling beyond the target |
| **Predictability** | Whether patterns generalize across the codebase | Uniformity of naming, structure, and action vocabulary |
| **Blast radius** | Files touched by a representative change | File count for a single-behavior modification |

All scores are informed by evidence from the actual codebases: file counts, line counts, directory listings, and structural observations.

## Family Analysis

### Family 1: Controller Basics (1A-1B)

| Branch | CWC | DISC | ISOL | PRED | BLAST | Total |
|---|---|---|---|---|---|---|
| 1A-fat-controller | 2 | 3 | 1 | 2 | 2 | **10** |
| 1B-extract-concerns | 3 | 4 | 2 | 3 | 3 | **15** |

**1A-fat-controller** is the baseline and lowest-scoring branch. Four domain controllers average 244 lines each. A representative task ("fix a bug in task item completion") requires loading 363 lines across 2 files -- a 36x signal-to-noise ratio for a 10-line fix. Authorization uses three different strategies across four controllers. `require_comment_author!` and `comment_params` are duplicated across two controllers. The mirrored `except:/only:` `before_action` pair in `UsersController` (lines 4-17) is a correctness trap -- adding one action requires editing both lists in sync.

**1B-extract-concerns** improves every dimension by +1. 15 concern files follow a uniform structure with descriptive names (`task_lists_transfers_concern.rb`). Median concern is 49 lines vs. 244-line controllers. Controllers become manifests: `UsersController` is 28 lines of `include` statements. The key trade-off: 1B is cheaper to load but harder to reason about correctly -- an agent working in `AccountsInvitationsConcern` cannot determine which actions are public vs. authenticated without also loading the host controller. Duplicated methods are moved but not eliminated; the mirrored `except:/only:` trap persists.

### Family 2: REST Discipline (2A-2B)

| Branch | CWC | DISC | ISOL | PRED | BLAST | Total |
|---|---|---|---|---|---|---|
| 2A-multi-controllers | 3 | 3 | 4 | 3 | 4 | **17** |
| 2B-rest-actions-only | 4 | 3 | 4 | 4 | 4 | **19** |

**2A-multi-controllers** replaces concerns with 21 dedicated controllers (median 48 lines). Each controller owns its own `before_action`. Isolation is excellent (4/5). But 11 custom action names (`complete`, `my_tasks`, `mark_all_read`, etc.) break REST vocabulary. `TaskItemsController` at 160 lines with 10 actions is the bottleneck. The flat directory (21 files, no subdirectories) creates prefix-parsing noise.

**2B-rest-actions-only** eliminates all 11 custom actions. Every public action is one of the 7 standard REST verbs. `TaskItemsController` drops from 160 to 79 lines as completion/incompletion/move are extracted to dedicated controllers. `CompleteTaskItemsController` is 19 lines. A shared `TaskItemsConcern` (42 lines) keeps 4 controllers DRY. The decisive gain is predictability (+1): an agent can predict the action name from the controller name without reading it.

### Family 3: Namespacing & Structure (3A-3G)

| Branch | CWC | DISC | ISOL | PRED | BLAST | Total |
|---|---|---|---|---|---|---|
| 3A-namespaced-controllers | 3 | 3 | 2 | 3 | 3 | **14** |
| 3B-nested-namespaces | 3 | 4 | 2 | 3 | 3 | **15** |
| 3C-context-views | 3 | 4 | 3 | 3 | 3 | **16** |
| 3D-context-mailers | 3 | 4 | 3 | 4 | 3 | **17** |
| 3E-singular-resources | 3 | 4 | 3 | 3 | 3 | **16** |
| 3F-resource-discipline | 3 | 5 | 4 | 4 | 4 | **20** |
| 3G-domain-naming | 3 | 5 | 4 | 5 | 4 | **21** |

This family splits into three phases:

**Structure (3A-3C):** Filing convention. Context window cost is flat at 3/5 -- the representative task requires ~177 lines in every branch. 3A puts controllers into domain namespaces (`user/`, `account/`, `task/`). 3B adds nested namespaces (`task/item/complete_controller.rb`). 3C moves shared partials into domain directories, deletes dead files, and aligns view paths with controllers exactly.

**Contracts (3D-3E):** Explicit declarations replace implicit conventions. 3D aligns mailer naming with controller namespaces and introduces `default template_path:` -- the first fully consistent cross-stack pattern. 3E replaces 9 raw verb routes with DSL calls but introduces more override types (`controller:`, `param:`, `module:`), so predictability does not improve.

**Behavior (3F-3G):** The inflection point. 3F eliminates all route overrides by splitting mixed-audience controllers: `InvitationsController` (80 lines, all authenticated) and `AcceptancesController` (65 lines, all public). Discoverability reaches 5/5 -- every route is derivable from its resource name. 3G extracts password change from profile into a dedicated controller, achieving 5/5 predictability with one resource per controller and operation-accurate naming throughout.

### Family 4: Entry Points (4A-4B)

| Branch | CWC | DISC | ISOL | PRED | BLAST | Total |
|---|---|---|---|---|---|---|
| 4A-separation-of-entry-points | 2 | 4 | 3 | 3 | 2 | **14** |
| 4B-controller-deduplication | 3 | 4 | 4 | 4 | 3 | **18** |

**4A** splits every dual-format controller into `Web::` (27 files) and `API::V1::` (19 files). Discoverability is good (4/5) -- the namespace prefix tells an agent the format. The cost is severe duplication: `set_task_item` in 8 files, `owner_or_admin` query in 6 files, `next_location` in 4 files. Blast radius scores 2/5 -- shared logic changes require 2-8 files with no structural signal to find the siblings.

**4B** applies three standard Rails tools: inner base controllers (`Web::Task::Item::BaseController`, 32 lines), an `ApplicationController` predicate (`owner_or_admin?`), and a `CommentAuthorization` concern. `set_task_item` drops from 8 files to 2, `owner_or_admin` from 6 to 1, `next_location` from 4 to 1. Leaf controllers shrink to 12 lines. Irreducible cross-family duplication (`user_session_params`, `task_item_params`) remains at 2 files each.

### Family 5: Model Patterns (5A-5D)

| Branch | CWC | DISC | ISOL | PRED | BLAST | Total |
|---|---|---|---|---|---|---|
| 5A-fat-models | 4 | 3 | 3 | 4 | 3 | **17** |
| 5B-model-callbacks | 4 | 3 | 4 | 4 | 3 | **18** |
| 5C-unified-vocabulary | 4 | 5 | 4 | 5 | 3 | **21** |
| 5D-model-authority | 4 | 5 | 5 | 5 | 4 | **23** |

**5A** moves business logic (queries, predicates, `Data.define` value objects) from controllers to models. Context window cost is good (models average 48 lines). But flat model names (`TaskList` vs. controller `Task::List`) force two-query searches -- `grep 'TaskList'` finds 4 files, `grep 'Task::List'` finds 6 different files. Discoverability caps at 3/5.

**5B** moves side effects to `after_create_commit` callbacks. Isolation improves (+1) -- changing "what happens when an invitation is created" now requires 1 file instead of 2 controllers. But transparency drops: `@invitation.save` reveals nothing about the email it triggers. The `attr_accessor :to_user` on `TaskListTransfer` is a subtle coupling point.

**5C is the discoverability breakthrough.** Zero behavioral change, but 8 models renamed to match controller namespaces (`TaskList` -> `Task::List`, `Invitation` -> `Account::Invitation`). Now `grep 'Task::List'` finds 16 files -- controllers, models, views, and routes in a single search. File path derivation becomes mechanical: `Task::List::Transfer` -> `app/models/task/list/transfer.rb`. Discoverability jumps from 3 to 5, predictability from 4 to 5.

**5D** applies Tell Don't Ask: `account.owner_or_admin?(user)` replaces 5+ inlined membership chain queries across 4 files. `Task::Comment.for_account` is absorbed into `Account#search_comments`. Isolation reaches 5/5 -- changing membership rules requires editing 1 file (62 lines). Blast radius improves to 4/5.

### Family 6: Domain Objects (6A-6G)

| Branch | CWC | DISC | ISOL | PRED | BLAST | Total |
|---|---|---|---|---|---|---|
| 6A-member-object | 4 | 4 | 4 | 3 | 4 | **19** |
| 6B-token-secret | 4 | 4 | 5 | 4 | 5 | **22** |
| 6C-task-status | 4 | 4 | 3 | 4 | 4 | **19** |
| 6D-query-objects | 4 | 5 | 4 | 4 | 4 | **21** |
| 6E-declared-authority | 4 | 5 | 4 | 5 | 4 | **22** |
| 6F-contextual-names | 4 | 4 | 4 | 4 | 3 | **19** |
| 6G-named-orchestrations | 4 | 5 | 5 | 5 | 5 | **24** |

Family 6 is the gradient's best trade-off -- the highest scores with the least architectural overhead. It applies four extraction tools scaled to concept weight:

**POROs (6A, 6B):** `Account::Member` (75 lines) extracts authorization from `Current` (82 -> 20 lines). `User::Token::Secret` (47 lines) extracts crypto from the AR model with zero database access. 6B achieves 5/5 isolation and 5/5 blast radius -- changing the hash algorithm touches 1 file, zero tests changed.

**Constants (6C):** `Task::COMPLETED` / `Task::INCOMPLETE` replace ~19 scattered string literals. A typo produces `NameError` at load time instead of a silent bug. Isolation dips to 3/5 because the extraction is a naming change without structural reorganization.

**Query objects (6D):** `Account::Search` (39 lines) and `Task::List::Stats` (34 lines) with `Data.define` return contracts. The file names perfectly match the concepts. Discoverability reaches 5/5. Host models keep one-line delegations.

**Declared authority (6E):** 28-file sweep applying "each model declares its own authority." `Membership` gains role constants + enum. `Notification` gains `ACTIONS` array. `ApplicationHelper` drops from 81 to 33 lines. Predictability reaches 5/5 -- one uniform rule across the codebase.

**Contextual names (6F):** `task_items` -> `items` inside `Task::` namespace. 42-file mechanical change. Discoverability drops to 4/5 because the dual naming system adds a boundary rule: inside the namespace it is `list.items`, but at the `Account` boundary it remains `account.task_lists`.

**Named orchestrations (6G):** 6 orchestration objects extracted from model callbacks. `User::Registration` (40 lines), `Account::Invitation::Lifecycle` (35 lines), `Task::List::Transfer::Facilitation` (51 lines), `User::Notification::Delivery` (24 lines). Models shrink to pure structure (zero callbacks). `User` drops from 80 to 50 lines. Average model drops from 45 to 34 lines. Every workflow is explicit -- `User::Registration.new.create(params)` vs. hidden `after_create` callbacks. **6G is the gradient's peak at 24/25.**

### Family 7: Domain Architecture (7A-7D)

| Branch | CWC | DISC | ISOL | PRED | BLAST | Total |
|---|---|---|---|---|---|---|
| 7A-domain-boundaries | 4 | 3 | 4 | 4 | 4 | **19** |
| 7B-process-managers | 4 | 3 | 4 | 4 | 4 | **19** |
| 7C-domain-databases | 4 | 3 | 4 | 3 | 3 | **17** |
| 7D-shared-kernel | 5 | 2 | 5 | 3 | 4 | **19** |

Family 7 builds on top of Family 6 -- the domain layer (`app/models/`) retains all of its self-revealing patterns. What Family 7 adds is infrastructure-level isolation: bounded contexts, separate databases, engine extraction. The domain model is still cohesive and discoverable; the added complexity lives in the representation layer and the mapping between presentation naming and domain naming.

The orthogonality between `Web::Task::*` controllers and `Workspace::*` models is not a defect -- it is deliberate decoupling that gives the view layer freedom to name things for the user, independent of how the domain names things for itself. This freedom comes at a cost: an agent navigating from a route to a model must cross a naming boundary. For this codebase's size, that complexity exceeds what is needed. But the gradient exists to prove that Rails and Ruby can take you all the way -- bounded contexts, separate databases, engine extraction -- without leaving the framework.

**7A** introduces three bounded contexts (User, Account, Workspace) with no cross-domain `belongs_to`. Models average 26 lines/file. The naming drift between `Web::Task::*` controllers and `Workspace::*` models caps discoverability at 3/5. The Jbuilder shim `json.task_list_id item.workspace_list_id` creates a dead-end search path.

**7B** adds `Manager = Struct.new(...)` to 2 of 6 process jobs (+26 LOC). State declarations make cross-domain orchestration visible. Identical score to 7A -- targeted and proportional.

**7C** gives each context its own SQLite database with saga compensation. The `Orchestrator` module (in `lib/`, not `app/`) introduces concepts beyond standard Rails (`undo`, `Revertible`, `revert!`). Adding a process step requires coordinated changes across databases. Predictability and blast radius both drop -- **score 17/25** -- reflecting that database-per-context is an ambitious choice whose infrastructure cost is felt most by agents.

**7D** splits controllers into mountable engines (`engines/web/`, `engines/api/`). The host kernel retains only models, jobs, and mailers (1228 LOC). Context window cost reaches 5/5 (best in the gradient) -- an agent working on the API never loads web code. Isolation reaches 5/5 (physical code separation via Ruby load paths). Discoverability drops to 2/5 because the representation layer now spans three locations (host + two engines). **Net score 19/25** -- the infrastructure ambition is real, but the domain layer remains as clear as Family 6.

## Cross-Family Rankings

| Rank | Branch | CWC | DISC | ISOL | PRED | BLAST | Total |
|---|---|---|---|---|---|---|---|
| 1 | **6G-named-orchestrations** | 4 | 5 | 5 | 5 | 5 | **24** |
| 2 | **5D-model-authority** | 4 | 5 | 5 | 5 | 4 | **23** |
| 3 | 6B-token-secret | 4 | 4 | 5 | 4 | 5 | **22** |
| 3 | 6E-declared-authority | 4 | 5 | 4 | 5 | 4 | **22** |
| 5 | 3G-domain-naming | 3 | 5 | 4 | 5 | 4 | **21** |
| 5 | 5C-unified-vocabulary | 4 | 5 | 4 | 5 | 3 | **21** |
| 5 | 6D-query-objects | 4 | 5 | 4 | 4 | 4 | **21** |
| 8 | 3F-resource-discipline | 3 | 5 | 4 | 4 | 4 | **20** |
| 9 | 2B-rest-actions-only | 4 | 3 | 4 | 4 | 4 | **19** |
| 9 | 6A-member-object | 4 | 4 | 4 | 3 | 4 | **19** |
| 9 | 6C-task-status | 4 | 4 | 3 | 4 | 4 | **19** |
| 9 | 6F-contextual-names | 4 | 4 | 4 | 4 | 3 | **19** |
| 9 | 7A-domain-boundaries | 4 | 3 | 4 | 4 | 4 | **19** |
| 9 | 7B-process-managers | 4 | 3 | 4 | 4 | 4 | **19** |
| 9 | 7D-shared-kernel | 5 | 2 | 5 | 3 | 4 | **19** |
| 16 | 4B-controller-deduplication | 3 | 4 | 4 | 4 | 3 | **18** |
| 16 | 5B-model-callbacks | 4 | 3 | 4 | 4 | 3 | **18** |
| 18 | 2A-multi-controllers | 3 | 3 | 4 | 3 | 4 | **17** |
| 18 | 3D-context-mailers | 3 | 4 | 3 | 4 | 3 | **17** |
| 18 | 5A-fat-models | 4 | 3 | 3 | 4 | 3 | **17** |
| 18 | 7C-domain-databases | 4 | 3 | 4 | 3 | 3 | **17** |
| 22 | 3C-context-views | 3 | 4 | 3 | 3 | 3 | **16** |
| 22 | 3E-singular-resources | 3 | 4 | 3 | 3 | 3 | **16** |
| 24 | 1B-extract-concerns | 3 | 4 | 2 | 3 | 3 | **15** |
| 24 | 3B-nested-namespaces | 3 | 4 | 2 | 3 | 3 | **15** |
| 26 | 3A-namespaced-controllers | 3 | 3 | 2 | 3 | 3 | **14** |
| 26 | 4A-separation-of-entry-points | 2 | 4 | 3 | 3 | 2 | **14** |
| 28 | 1A-fat-controller | 2 | 3 | 1 | 2 | 2 | **10** |

### Inflection Points

**Largest upward jumps:**

| Transition | Delta | What changes |
|---|---|---|
| 1A -> 1B | +5 | Concern extraction: first structural separation, every dimension improves |
| 5B -> 5C | +3 | Unified vocabulary: one grep covers all layers, discoverability jumps 3->5 |
| 3E -> 3F | +4 | Route overrides eliminated + audience splits: discoverability reaches 5/5 |
| 4A -> 4B | +4 | Deduplication absorbs Web/API split's copy-paste tax |
| 6E -> 6G | +2 (via 6F) | Named orchestrations eliminate hidden callbacks, isolation + blast radius reach 5/5 |

**Plateaus and regressions:**

| Transition | Delta | Why |
|---|---|---|
| Context window cost plateaus at 4/5 from 5A onward | 0 | No branch significantly changes lines loaded for a targeted task. Exception: 7D reaches 5/5 but trades discoverability |
| 6F regresses in blast radius | -1 from 6E | 42-file mechanical rename with `source: :items` indirection trap |
| 7B -> 7C | -2 | Saga compensation adds non-standard patterns; predictability and blast radius drop |
| Family 7 is flat at 19/25 | 0 | Domain architecture trades discoverability for isolation with no net gain |

### Score progression through the gradient

```
Branch    Total   Visual
1A         10     ████
1B         15     ██████
2A         17     ███████
2B         19     ████████
3A         14     ██████
3B         15     ██████
3C         16     ███████
3D         17     ███████
3E         16     ███████
3F         20     ████████
3G         21     █████████
4A         14     ██████
4B         18     ███████
5A         17     ███████
5B         18     ███████
5C         21     █████████
5D         23     ██████████
6A         19     ████████
6B         22     █████████
6C         19     ████████
6D         21     █████████
6E         22     █████████
6F         19     ████████
6G         24     ██████████
7A         19     ████████
7B         19     ████████
7C         17     ███████
7D         19     ████████
```

Three saw-tooth patterns are visible:

1. **The duplication dip (3G->4A->4B):** Splitting into Web/API duplicates code before 4B de-duplicates it. Agent-friendliness drops from 21 to 14 before recovering to 18.
2. **The extraction restart (5D->6A):** Family 6 begins new extraction work from a lower baseline. Agent-friendliness drops from 23 to 19 before climbing to 24 at 6G.
3. **The saga dip (7B->7C):** Database separation introduces non-standard patterns. Agent-friendliness drops from 19 to 17 before partially recovering at 7D.

Each dip represents a branch where architectural ambition temporarily outpaces the naming and structural signals agents rely on. The patterns recover as the codebase absorbs the new complexity -- deduplication follows the Web/API split, named orchestrations follow model extraction, and engine isolation follows database separation.

## Guidance Requirements

Agent-friendliness has two dimensions: how much the **code explains itself** vs. how much needs **external guidance** (CLAUDE.md, .cursorrules, or similar). The gradient reveals that Families 1-6 are largely self-explanatory -- the code's naming, structure, and cohesion do the teaching. Family 7's domain layer inherits this quality from Family 6; the guidance it needs is specifically for the **infrastructure and representation layers** -- the mapping between how the domain names things and how the presentation layer and databases are organized.

```
Family   CLAUDE.md lines   Guidance profile
1-3           10-20        Standard Rails -- almost self-explanatory
4             25-30        Web/API dual-tree rule
5             30-35        Tell Don't Ask as an explicit rule
6             15-20        Code reveals itself -- just note that app/models/ holds all domain objects
7A           80-100        Route-to-model naming map + UUID coordination
7C          120-150        3 databases, 3 migration dirs, 3 abstract bases
7D          150-200        Engine placement guide + BOOT/MOUNT env vars
```

### Why Family 6 needs almost no guidance

An agent encountering `Account::Invitation::Lifecycle` for the first time does not need a CLAUDE.md entry explaining what a "Lifecycle" is. It opens a 35-line file, reads cohesive code with a clear `initialize` + named methods, and understands the concept. That is the entire point of the extraction: small files, descriptive names, loose coupling. The code IS the documentation.

What makes this work is that every extracted object lives inside `app/models/` -- the domain model. There is no `app/services/`, no `app/interactors/`, no separate directory that an agent must learn about. The namespace nesting tells the agent where the concept belongs: `Account::Invitation::Lifecycle` is nested under the entity it orchestrates. An agent following the namespace path arrives at the right file.

The only guidance Family 6 needs is a single note: "all domain objects -- including non-ActiveRecord classes -- live in `app/models/`." Everything else is discoverable from the code itself.

### Where guidance bridges the orthogonality gap: Family 7

**Families 1-5** need minimal guidance. Standard Rails conventions carry the weight. The only custom rules are project-specific conventions: "use singular namespace prefix" (Family 3), "every feature must work in both `web/` and `api/v1/`" (Family 4), "models own all business logic" (Family 5). An agent can infer these from reading a few files, but stating them prevents drift.

**Family 7's domain layer is Family 6** -- still self-revealing, still cohesive. The guidance it needs is for the orthogonality between domain and representation:

- **7A** needs a **route-to-model mapping table** because the deliberate decoupling between presentation names (`Web::Task::*`) and domain names (`Workspace::*`) is not derivable from code alone. The domain layer is clear; the bridge between layers needs documenting. A CLAUDE.md mapping table and a note about UUID as the cross-boundary identity key are enough.
- **7C** adds database-level isolation, which introduces infrastructure rules that an agent cannot infer: which abstract base to inherit from (`Abstract::Account` vs `ApplicationRecord`), which migration directory to use, and the fact that cross-database transactions are not atomic. Getting the abstract base wrong risks writing to the wrong database -- this is where guidance becomes a safety requirement.
- **7D** adds engine-level isolation. Controllers go in engines, models stay in the host kernel, mailers need injected URL helpers, each engine has its own `Current` class. These are infrastructure placement rules that serve organizational needs (independent deploys, selective booting). An agent working within a single engine or within the domain model has a clear experience; the guidance is for navigating between them.

### The guidance spectrum

| Family | Self-explanatory? | Failure mode without guidance |
|---|---|---|
| 1-5 | Almost entirely | Minor convention drift |
| 6 | Yes -- cohesive code reveals itself | Negligible (agent reads a 35-line file) |
| 7A | Needs naming map | Wasted search time (confusing, not dangerous) |
| 7C | Dangerous without docs | Silent data corruption (wrong database) |
| 7D | Maximum guidance | Loud errors (wrong engine) but high onboarding cost |

This spectrum reinforces the sweet-spot finding: **Family 6 achieves peak agent-friendliness scores (24/25) while being almost entirely self-explanatory.** The code's cohesion and naming do the work that a CLAUDE.md would do elsewhere. Family 7's domain layer inherits this quality; the guidance it needs (80-200 lines) is specifically for the infrastructure and representation mapping -- the price of orthogonality between layers. That price is justified when teams need independent deploys, selective booting, or database-level isolation. The gradient proves Rails and Ruby can deliver all of this without leaving the framework.

## Conclusion

### The architectural sweet spot

The agent-friendliness peak is **6G-named-orchestrations (24/25)**, followed by **5D-model-authority (23/25)**. The sweet spot spans the **5C-6G range** where three properties converge:

1. **Every file can be found by name** -- unified vocabulary means one grep covers all layers
2. **Every method can be predicted from convention** -- REST verbs, `Data.define` contracts, named orchestrations
3. **Every change touches the minimum number of files** -- authority consolidated on owning models, no duplication

### What makes code agent-friendly

The gradient reveals three principles that hold regardless of which family your codebase resembles:

**1. Name everything.** The single highest-leverage investment is giving every concept a discoverable name. Unified vocabulary (5C) transforms agent search from two queries to one. Named orchestrations (6G) make hidden callbacks explicit. Query objects (6D) make return contracts visible via `Data.define`. The branches scoring 5/5 on discoverability (3F-3G, 5C-5D, 6D-6E, 6G) all achieve this.

**2. Match the tool to the concept's weight.** The gradient demonstrates four extraction tools -- POROs, constants, query objects, and orchestration objects -- each appropriate to different concept sizes. Over-engineering (7C's saga pattern) adds cognitive load without proportional benefit. Under-engineering (1A's fat controllers) forces agents to load everything at once. The right tool makes concepts visible without adding indirection.

**3. Naming boundaries serve agents; physical boundaries serve teams.** Family 6's named orchestrations achieve 5/5 isolation through clear responsibility assignment -- an agent finds and modifies code through naming alone. Family 7's engine split achieves 5/5 isolation through physical code separation, which serves organizational needs (independent deploys, team ownership). Both are valid; for agents specifically, the naming boundary delivers the most direct benefit. When physical boundaries are justified, pairing them with a CLAUDE.md that bridges the representation-to-domain mapping closes the gap.

### The practical takeaway

For a codebase optimized for agent collaboration, the highest-leverage changes are:

- **Unify naming across layers** (5C pattern): one grep covers models, controllers, views, and routes
- **Declare and consolidate authority on owning models** (5D + 6E pattern): every question has one address -- constants, predicates, and queries live on the model that owns the data, establishing a global rule agents can rely on
- **Name orchestrations explicitly** (6G pattern): replaces invisible callbacks with findable workflow objects
- **Eliminate route overrides** (3F pattern): makes every route self-resolving from the DSL

These four patterns compound. Applied together, they create a codebase where an agent's first guess about where to look is correct, and the file it finds contains the complete answer.

If your architecture goes beyond Family 6 into domain boundaries or engine extraction, **pair the orthogonality with proportional guidance** -- a CLAUDE.md that bridges the representation-to-domain naming, documents database ownership, and specifies engine placement rules. The complexity is not bad; it serves real organizational needs. The guidance makes the agent experience match the domain layer's clarity.

The gradient's broadest lesson: **you do not need to leave Rails or Ruby to achieve any of this.** From fat controllers to bounded contexts with separate databases and engine extraction, the framework and language adapt. The question is not *whether* Rails can handle the architecture, but *how much* architecture your codebase actually needs -- and for agents, the answer is usually Family 6.
