# Branch Conventions

> Operational details for [Principle 7: Branches argue a thesis](../governance/CONSTITUTION.md#principle-7-branches-argue-a-thesis) in the Constitution.

---

## Branch naming

**Format:** `NL-concept-name` (e.g., `1A-fat-controller`, `1B-extract-concerns`)

- **Single digit (`N`)** = concept family — all branches sharing the same digit explore the same design problem
- **Uppercase letter (`L`)** = arc position — A is always the raw problem; the final letter is the resolved/best version
- **2–4 branches per family max** (letters A–D) — letters are contiguous, no skipping
- **Family 0** = infrastructure branches (`0A-skeleton`, `0B-tests-and-docs`) — setup before the teaching arc
- **`99-*`** = meta/special branches outside the arc — unchanged
- **Name the design concept or problem**, not the implementation structure
- **Keep it short** — branch name is the lesson title, not a description
- Use lowercase kebab-case

---

## Commit messages

**Format:** Plain English, capital first letter, no trailing period.

```
Design plans and Claude configuration
Working app with one controller per entity
Testing infrastructure, documentation, and dev tooling
```

Rules:
- **Start with a capital letter** — always
- **No conventional-commit prefix** — do not use `feat:`, `fix:`, `refactor:`, `chore:`, etc.
- **No branch name** in the message — the branch is already in `git log`
- **No trailing period**
- Use a gerund phrase (`Adding X`), noun phrase (`New X behavior`), or adjective phrase (`Bare X scaffolding`) — not imperative mood (`Add X`)
- Keep it concise — one line unless a body is genuinely needed

---

## README purpose

The README's architecture section exists to prove the project's thesis — that well-organized MVC scales without service objects. Do not move it to a separate doc to "clean up" the README. It belongs there because it IS the evidence.

What belongs in README: thesis, architecture (with real line counts and named tradeoffs), quick start, testing, background.

What does not belong in README: feature lists, API references, installation details.

---

## README style

The README can be long. This project exists to **teach humans and guide coding agents**. Write as much as the content requires — evidence, rationale, code examples, design analysis. Prioritize clarity and teaching value over brevity.

**Communication style:** Use emojis in READMEs and documentation. Emoji-prefixed section headers (e.g., `## 📢 Disclaimer`, `## 🙌 Repository branches`), inline emojis for personality (✌️😊, 🤘😎). The project emoji is **🦾** (as defined in the [Manifesto](../governance/MANIFESTO.md)) — use it as the primary project identity marker.

**Writing quality:** Use the humanizer skill to produce and review READMEs and other end-user documentation. It removes AI writing patterns (inflated significance, promotional language, vague attributions, filler phrases). **Override:** the humanizer's emoji removal pattern does not apply — this project uses emojis intentionally per the communication style above.

---

## Rubycritic score

Every branch README must include the **Rubycritic score** in its metadata table. It is the primary quality metric tracked across branches — a single number to compare branch-to-branch.

- **Where it goes:** In the metadata table at the top of the README, immediately after the branch description
- **How to get it:** `bin/rails rubycritic` — outputs `Score: XX.XX` at the end (also part of `bin/ci`)
- The HTML report lands in `tmp/rubycritic/` but is gitignored

---

## README structure

Each branch README follows a two-part structure: a **narrative arc** that argues the branch's thesis, and **operational sections** that stay mostly stable across branches.

### Fixed elements (every branch)

**Navigation bar** — first line, inside `<small>` tags. See [Documentation](./documentation.md#navigation-menus) for format, menu groups, and rules.

**Title** — project name, TOC-excluded. Uses mechanical arm images instead of emoji:

```markdown
<h1 align="center" style="border-bottom: none;">
  <img src="./app/assets/images/emoji-mechanical-arm.png" alt="" width="36" height="36">
  Rails Whey App
  <img src="./app/assets/images/emoji-mechanical-arm-flipped.png" alt="" width="36" height="36">
</h1>
```

The title is the same on every branch. The branch identity goes in the metadata table, not the heading.

**Branch description** — one paragraph immediately after the title. Describes what *this branch* is and the design concept it demonstrates. Written as a standalone sentence a reader can understand without context.

**Metadata table** — immediately after the description:

```markdown
| | |
|---|---|
| **Branch** | `NL-concept-name` |
| **Ruby** | 4.x |
| **Rails** | 8.x |
| **Rubycritic** | XX.XX |
```

**Table of contents** — emoji-prefixed anchors for all narrative and operational sections.

### Narrative arc (branch-specific)

The narrative sections tell the branch's story. They follow an argumentative structure — not a feature list:

| Section | Purpose |
|---|---|
| 🎯 **The concept** | What this branch demonstrates — the design idea in its simplest form |
| 📊 **The numbers** | Quantitative evidence — line counts, file counts, concrete measurements |
| 🤔 **The problem** | What's wrong with the current state — name the design weakness |
| 🏭 **Why it happens** | Root cause — how the pattern emerges naturally |
| 🔬 **The evidence** | Detailed proof — code examples, action lists, `before_action` analysis |
| ➡️ **What comes next** | Forward pointer — what the next branch addresses |
| 🤖 **The agent's view** | Honest assessment of structural impact on coding agents — token overhead, correctness risk, compounding cost |

Rules:
- **Every narrative section is required** on every branch — the arc is the teaching structure
- Sections can vary in length — some branches need more evidence, some need more problem analysis
- Use code blocks with real code from the branch, not pseudocode
- Name weaknesses honestly — the project teaches by contrasting, not by selling
- The "what comes next" section must connect to the next branch's concept by name

**"What comes next" workflow:** Before starting a new branch, update the previous branch's "➡️ What comes next" to point forward to the new branch's concept. The new branch's "➡️ What comes next" starts blank until the next branch is defined.

### Operational sections (stable across branches)

These sections provide setup and context. They change only when the stack or tooling changes:

| Section | Content |
|---|---|
| **Quick start** | Prerequisites + clone + `bin/setup` |
| **Testing** | `bin/ci` + individual test commands |
| **Background** | Project context, link to v1, what v2 adds |

Rules:
- Keep operational sections at the bottom, after the narrative arc
- No emoji prefixes on operational headers — they are utility, not argument
- Update only when the underlying commands or context actually change

### Horizontal rules

Use `---` to separate every top-level section (both narrative and operational). This matches the project's visual rhythm and gives each section room to breathe.

### Self-evaluation when applying this template

This structure was extracted from a single branch. It may not fit every future branch equally well. When writing or reviewing a README, actively check whether the template is helping or getting in the way.

**Before writing**, ask:
- Does this branch's story actually have six distinct narrative beats, or am I forcing content into sections that don't earn their place?
- Would merging two sections (e.g., "the numbers" into "the evidence") make the argument stronger?
- Does this branch introduce something the template doesn't account for (e.g., a before/after comparison, a migration guide)?

**After writing**, check:
- Am I padding a section just because the template says it's required? Empty calories weaken the argument.
- Does the README read as a coherent essay, or as a form being filled out?
- Would a reader notice the template, or does the content feel natural?

**If the template is fighting you**, say so. Flag it to the user with a concrete proposal: which sections to merge, drop, or add for this specific branch. Then suggest updating this decision if the change applies broadly. The template exists to promote consistency — not to override judgment. One branch that genuinely needs a different structure is a signal to evolve the template, not to force-fit the content.

---

## Agent-impact analysis

Every branch README must include a **🤖 The agent's view** section — placed after the narrative arc, before Quick start.

**Structure:**
- Open with a blockquote stating the hard constraint (e.g., `> Coding agents operate under a hard constraint: context windows are finite...`). This frames the analysis before any evidence is presented.
- No sub-headers — prose only. Three paragraphs covering three dimensions in order:
  1. **Token overhead** — quantify the cost of the branch's structure. Use real numbers: file size, relevant lines, ratio (e.g., "9x token overhead for a targeted change").
  2. **Correctness risk** — name what breaks reasoning, not just efficiency. Ambiguous filters, opposing access rules, unrelated concerns in the same file — these cause agents to pattern-match incorrectly across concerns.
  3. **Compounding cost** — explain how the structure scales. Fat files grow; every new feature increases the overhead on every future agent interaction with that file, not just the new one.

**How to frame it:**
- Diagnostic only — no prescriptions, no forward pointers to solutions
- Written from the agent's POV, not the developer's
- Honest about severity: if something is bad, say how bad and why
- Concrete numbers beat vague claims — use real line counts, real ratios from the branch

**What to avoid:**
- Sub-headers inside the section — the three-paragraph structure carries the analysis without them
- Describing tools or workflows for working with agents
- Suggesting architectural improvements (that's the next branch's job)
- Generic claims ("agents work better with clean code") without tying them to specific evidence from this branch
