# ProgressablesResultPresenter

## What it is
`ProgressablesResultPresenter<C extends AbleCubit<S>, S>` plus `ProgressableResultPresenter`
(`lib/src/widgets/progressables_result_presenter.dart`) — a `StatefulWidget` that subscribes to a
cubit's `stream`, diffs each listed `Progressable` field against its previous value, and fires
`onSuccess`/`onError` exactly once per idle->success / idle->error transition.

## Why it exists
To centralize "navigate away on save" / "toast on failure" side effects for one-shot actions,
replacing ad hoc `BlocListener`s that would each reimplement transition-detection and the
`shouldIgnoreMessage` ignore-list.

## Where it lives
`lib/src/widgets/progressables_result_presenter.dart`.

## What it depends on
- [[Progressable]] — the value it diffs.
- [[AbleCubit]] — generic bound `C extends AbleCubit<S>`; reads `context.read<C>()` and `.stream`
  directly (bypassing `mapPStream`).
- [[ExceptionHandler]] — calls `.onError` for errors not suppressed by `shouldIgnoreMessage`
  (reachable since 0.1.0; see [[ExceptionHandler]]'s fixed defect 1). It subscribes to the cubit
  in `initState` (since 0.1.0; before, it waited for the first frame and missed earlier changes)
  and reports `Progressable.error(null)` too.

## What depends on it
Nothing inside the package.

## Which rules govern it
- `rules/patterns.md` item 7 (batching multiple presenters, `errorToMessage`'s near-zero real
  use).
- `rules/anti-patterns.md` #5 (vs. `BlocListener` — and the clarified exception for syncing a
  `Fetchable`'s payload into imperative widget state, which is `BlocListener`'s job, not this
  widget's).

## Which decisions affect it
- [[ADR-004-centralized-exception-handling]]

## Examples of correct usage
See `rules/patterns.md` item 7.

## Common mistakes
See `rules/anti-patterns.md` #5. Do not rely on `errorToMessage` to customize the generic error
message — real screens instead write a per-presenter `onError:` callback, partly because the
generic `Able.configs.onError` path it would otherwise feed into does not actually fire (see
[[ExceptionHandler]]).
