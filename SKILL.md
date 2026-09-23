---
name: able
description: >
  Guidance for using Gedeon's `able` Flutter state-management package, and the entry point to
  its knowledge base (rules/ + knowledge/). Use when a Flutter task involves state management,
  asynchronous state, Cubits, Fetchable/Progressable patterns, other able APIs, or any question
  about why this project's architecture is the way it is.
---

# able

`able` is Gedeon's state-management package: `AbleCubit` (a `Cubit` subclass with
stream-execution helpers) plus two immutable async-state wrappers, `Fetchable<D>` and
`Progressable`, and the widgets that render them. Every cubit in a Gedeon Flutter project extends
`AbleCubit`; every piece of async state is a `Fetchable`/`Progressable`, never a hand-rolled
loading/error/data trio.

This repository is also structured to be **the source of truth for this project's architectural
knowledge** — not any single conversation's memory. A fresh session with no prior context should
be able to read this file, follow it into `rules/` and `knowledge/`, and implement a change
consistently with everything established so far. That is this file's job.

```
lib/                  The package itself — always authoritative for exact behavior.
test/                 Regression tests for the 0.1.0 fixes, plus presenter tests.
example/
  counter/             Smallest possible AbleCubit app.
  country_listing/     Reference implementation of every rule: business + view cubits, tests.
rules/                NORMATIVE. MUST/SHOULD/MUST NOT usage rules. Concise, actionable.
knowledge/
  concepts/            WHAT each architectural entity is, one file per concept.
  decisions/           WHY — ADRs, grounded in real evidence, not invented history.
  graph/               Machine-readable index of concepts/rules/decisions and how they relate.
SKILL.md               This file.
```

## Authority order

When these disagree, this is the precedence — **and a disagreement is reported, never silently
resolved by picking whichever side is convenient**:

1. **Actual current source code** (`lib/`) — what the package really does right now.
2. **Explicit accepted decisions** (`knowledge/decisions/ADR-*.md`) — why it's shaped that way.
3. **Explicit project rules** (`rules/*.md`) — what you MUST/SHOULD/MUST NOT do.
4. **Concept documentation** (`knowledge/concepts/*.md`) — what an entity is, summarized.
5. **General documentation** (`README.md`) — background, may be stale.
6. **Your own assumptions** — lowest priority; if nothing above answers the question, say so
   rather than guessing silently.

If the source code contradicts a rule, do not treat the code as automatically correct and do not
treat the rule as automatically correct either. State it plainly: "Rule says X. Current
implementation does Y. This is a knowledge inconsistency." Then work out whether the code should
change to match the rule, or the rule should change because the architecture intentionally moved
on — and say which, with evidence. Earlier inconsistencies of this kind (the `ExceptionHandler`
defects, the `combine7F`–`combine9F` bug, `asFuture` after an error) were documented first, then
fixed in 0.1.0 with regression tests in `test/regression_test.dart`; their history stays in the
docs. Treat any newly discovered one the same way: document it, don't quietly normalize it.

## Workflow for a task

1. **Understand the task.** What's being built/changed, and does it touch async state, a cubit,
   or a widget that renders one?
2. **Identify relevant concepts.** Skim `knowledge/README.md`'s concepts index, or
   `knowledge/graph/graph.json` if you're not sure which concept applies yet (see "Discoverability"
   below).
3. **Identify applicable rules.** Every concept file lists "Which rules govern it" — read those
   `rules/*.md` sections, not the whole file if it's long.
4. **Identify related ADRs.** Every concept file lists "Which decisions affect it"; cross-check
   against `knowledge/decisions/README.md`'s index. An ADR explains *why* a constraint exists —
   useful when you're tempted to work around it.
5. **Inspect relevant graph relationships.** `knowledge/graph/graph.json` — what does this concept
   depend on, what depends on it, is it governed by more than one rule file? (`jq` examples in
   `knowledge/graph/README.md`.)
6. **Inspect the actual source code** in `lib/` for the concept(s) involved — rules and concept
   docs describe intent and usage; the source is what actually runs.
7. **Implement the change**, following the applicable rules and matching the patterns already
   established (see `rules/patterns.md` for consuming-app conventions like the business-cubit/
   view-cubit split).
8. **If the change affects a documented pattern**, update `example/country_listing/` to match and
   run `flutter analyze` and `flutter test` there.
9. **Check whether the change introduces:**
   - a new architectural rule (a pattern that should now be mandatory project-wide),
   - a new reusable pattern (worth a `rules/patterns.md` recipe),
   - a new concept (a new architectural abstraction worth its own `knowledge/concepts/*.md`),
   - a new architectural decision (worth an ADR),
   - a new dependency relationship (worth a `knowledge/graph/graph.json` edge).
10. **Update the knowledge base when appropriate** — see "Knowledge maintenance" below. Retrieval
   happens *before* implementation; maintenance happens *after*.

## Discoverability — narrowing a task to the right knowledge

You should not need to read every file for every task. Two worked examples of the intended
narrowing:

```
"Add a new API feature that fetches data"
  -> knowledge/concepts/Fetchable.md
  -> rules/fetchable.md, rules/state-management.md
  -> ADR-001 (stream-based state), ADR-002 (Fetchable vs Progressable)
  -> lib/src/fetchable/*.dart
```

```
"Add a repository-backed feature to a consuming app"
  -> knowledge/concepts/BusinessCubit.md, knowledge/concepts/ViewCubit.md
  -> rules/architecture.md ("Consuming-app conventions"), rules/patterns.md items 9-20
  -> example/country_listing/ (working code for the whole shape, with tests)
  -> (no ADR — these are observed conventions, not package-level decisions; see
      knowledge/decisions/README.md's "What is not here")
```

When you can't yet name a concept, `knowledge/graph/graph.json` is the index to search — every
node has a one-line `summary`, and `governed_by`/`decided_by` edges point you at the next file to
open. It is not meant to be read cover-to-cover; query it (`jq`, or just `grep`) for the node
closest to your task, then follow its edges.

## Knowledge maintenance — when to update, after implementing

Update the knowledge base when a change introduces:

- **A new concept** — a genuinely new, reusable architectural abstraction (not every new class —
  a one-off helper doesn't need a concept file; a new cross-cutting mechanism other code will
  build on does).
- **A new rule** — a pattern that should now be *mandatory* across the project, not just something
  you did once.
- **A new decision** — a meaningful architectural choice with real trade-offs, especially one that
  overrides or narrows an existing rule.
- **A new relationship** — a significant dependency between concepts that isn't in
  `knowledge/graph/graph.json` yet.
- **Changed architecture** — an existing rule, concept, or ADR that the current change makes
  obsolete. Update it in place rather than leaving a stale file next to the new reality — but
  never delete evidence of a real historical decision; mark it superseded instead.

Do **not** update the knowledge base for trivial implementation details — a bug fix inside a
single method, a naming tweak local to one file, a new test. If you're unsure whether something
rises to this bar, prefer not updating over inventing a rule/concept/ADR to justify the update.

When you do update:
- New concept -> `knowledge/concepts/<Name>.md`, matching the section headers used by every
  existing concept file (What it is / Why it exists / Where it lives / What it depends on / What
  depends on it / Which rules govern it / Which decisions affect it / Examples of correct usage /
  Common mistakes).
- New rule -> the existing `rules/*.md` file it belongs to (create a new file only if none of the
  six existing ones fit — don't create files for their own sake).
- New decision -> `knowledge/decisions/ADR-NNN-slug.md` (next sequential number), following the
  template in the existing ADRs, and add it to `knowledge/decisions/README.md`'s index. **If you
  cannot find real evidence for *why* — a README passage, a commit, a stated rationale — write
  "Not documented in the repository" rather than inventing a plausible-sounding one.** An ADR
  without a traceable Context is worse than no ADR.
- New relationship -> add the edge to `knowledge/graph/graph.json`, using one of the eight
  relation kinds documented in `knowledge/graph/README.md`. Only add an edge you can point at
  actual code, rule prose, or an ADR to justify.
- Then run `dart run tool/validate_knowledge.dart` (no `pub get` needed — it only uses
  `dart:core`/`dart:io`/`dart:convert`) and fix anything it reports before considering the update
  done. It catches: dangling graph references, duplicate node ids, invalid relation kinds,
  malformed JSON, and orphaned/missing concept, rule, or ADR files.

## Known gaps (flagged, not silently worked around)

- **Test coverage is still partial.** `test/regression_test.dart` covers the 0.1.0 bug fixes;
  most other behavior is exercised only by the example apps' tests (`example/*/test/`). Run all
  of them after a package change.
- The stream-receiver `stream.executeF(cubit, ...)`/`stream.executeP(cubit, ...)` extensions are
  deprecated (they ignore the stream) and should be removed in a later breaking release.

## Important distinctions

The package source under `lib/` is authoritative for exact API behavior and signatures — `rules/`
and `knowledge/` describe intent, convention, and rationale, and can drift from it; that's exactly
why authority order above puts source code first and why contradictions get reported rather than
silently resolved.

`rules/` is normative (MUST/SHOULD/MUST NOT); `knowledge/concepts/` and `knowledge/decisions/` are
descriptive (what things are, why they're that way). Don't promote a concept doc's prose to
rule-like authority, and don't demote a rule to "just background" — they answer different
questions.

Do not copy code from `rules/`/`knowledge/` back into application code as if it were the package
API; always import from `package:able/able.dart` and let the compiler/analyzer confirm the surface
is still accurate.
