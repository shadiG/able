# Knowledge base

This directory is the non-normative half of `able`'s documentation — the normative half is
`../rules/`. Together with `../SKILL.md` (the entry point), this is how a fresh Claude session (or
a new engineer) is meant to learn this project's architecture without relying on chat history.

```
../rules/           WHAT to do / not do — MUST/SHOULD/MUST NOT rules, concise and actionable.
concepts/            WHAT each architectural entity IS — one file per concept, cross-linked to
                      the rules that govern it and the decisions that shaped it.
decisions/           WHY the architecture is the way it is — ADRs, grounded in real evidence
                      (README text, commit history) or explicitly marked unknown.
graph/               A machine-readable index of concepts/rules/decisions and how they relate --
                      for targeted retrieval, not a duplicate of the source code.
```

## How to use this when implementing something

See `../SKILL.md` for the full workflow. In short: identify the relevant concept(s) in
`concepts/`, read the rule file(s) it names under "Which rules govern it", check
`decisions/README.md`'s index for any ADR that constrains the choice, then read the actual source
in `../lib/`. `graph/graph.json` exists to help you find the *first* concept/rule to open for a
task you can't yet name a concept for — see `graph/README.md`.

## Concepts index

Package-internal (defined in `lib/src/**`):
- `concepts/AbleState.md` — the shared idle/busy/success/error enum.
- `concepts/Fetchable.md` — async state with a result.
- `concepts/Progressable.md` — async state without a result.
- `concepts/AbleCubit.md` — the base cubit class and its `execute*`/`present*`/`rebuild` API.
- `concepts/AbleConfigs.md` — `Able.initialize`/`Able.configs`.
- `concepts/ExceptionHandler.md` — the shared error-routing singleton (**documents two verified
  defects — read this one if you're touching error handling**).
- `concepts/FetchableWidget.md`, `concepts/FetchableListWidget.md` — rendering.
- `concepts/ProgressablesResultPresenter.md` — one-shot success/error side effects.

Consuming-app conventions (observed in practice, not package classes):
- `concepts/BusinessCubit.md`, `concepts/ViewCubit.md` — the two-tier cubit pattern.

## Known gaps (not decisions — do not treat as intentional)

- **No test suite.** `test/able_test.dart` existed (added in commit `f5d7b65`, a `flutter_test`
  boilerplate default) and was deleted in commit `1b941b8` ("upgrade library"). The package
  currently ships `flutter_test`/`mockito`/`build_runner` as dev dependencies but has zero tests.
- `pubspec.yaml`'s `description:` field ("A new Flutter package project.") and `CHANGELOG.md`
  ("TODO: Describe initial release.") are still the unedited `flutter create --template=package`
  defaults, not a description of what `able` actually is.

These are flagged, not silently fixed, here — see the session's final report for why.
