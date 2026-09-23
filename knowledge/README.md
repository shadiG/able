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
graph/               A machine-readable index of concepts/rules/decisions/examples and how they
                      relate -- for targeted retrieval, not a duplicate of the source code.
../example/          Runnable apps. country_listing/ is the reference implementation of the
                      rules; each app has a README and a matching `example` node in the graph.
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

- **Thin test suite.** The package has one test file,
  `test/progressables_result_presenter_test.dart` (commit `b71d85d`). Most behavior is exercised
  only indirectly, by the tests in `example/country_listing/test/`.
- **`asFuture` keeps listening after an error** — a third package defect, found while testing
  `example/country_listing`. See `rules/cubits.md` ("One-shot reads") and
  `rules/anti-patterns.md` #10.
- `pubspec.yaml`'s `description:` field ("A new Flutter package project.") and `CHANGELOG.md`
  ("TODO: Describe initial release.") are still the unedited `flutter create --template=package`
  defaults, not a description of what `able` actually is.

These are flagged, not silently fixed, here — see the session's final report for why.
