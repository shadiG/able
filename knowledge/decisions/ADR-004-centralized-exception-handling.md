# ADR-004: A single configurable `ExceptionHandler` + `Able.initialize`, not per-call-site wiring

## Status
Accepted

## Context
Commit `614936f` ("Code refactor and error handler", 2023-06-17) introduced
`lib/src/common/able_type.dart` (`AbleType`) and substantially expanded `able_cubit.dart` and
`fetchable_utils.dart`/`progressable_utils.dart` to route errors through a shared handler. It was
reverted thirteen minutes later (`e993928`, "Revert \"Code refactor and error handler\"") and
then restored thirty-five seconds after that (`b91d7fd`, "Revert \"Revert \'Code refactor and
error handler\'\""), all within the same session on 2023-06-17 — indicating the design was
reconsidered before being deliberately kept. The callback was later renamed from `showError` to
`onError` (`e066442`, `05af16e`) for a clearer, UI-agnostic name (the original name implied a
snackbar/dialog; the callback is actually `void Function(dynamic e, String? message)` with no UI
coupling).

## Decision
`Able.initialize(loadingWidget:, errorWidget:, handleException:, onError:)` configures a
process-wide [[AbleConfigs]] singleton once; [[AbleCubit]]'s `presentF`/`presentP` route every
*unexpected* error (not matched by a call site's `isExpectedError`) through a single
[[ExceptionHandler]] singleton, tagged with an `AbleType` (fetchable/progressable), instead of
requiring each call site to wire its own logging/crash-reporting/toast handling.

## Consequences
- One place (`main()`) configures app-wide error UX — see `rules/architecture.md`,
  `rules/patterns.md` item 1.
- Reading `Able.configs` before `initialize()` throws; a second `initialize()` call is a silent
  no-op (`rules/anti-patterns.md` #6).
- **This design has two verified implementation defects that undermine part of its own intent --
  see [[ExceptionHandler]]'s "Known defect 1" and "Known defect 2".** The centralization decision
  itself is sound; the `ExceptionHandler` factory constructor's handling of the `onError` field,
  and `presentP`'s `AbleType` tagging, do not correctly implement it.

## Alternatives
Not documented in the repository. The revert/re-revert shows the design was reconsidered, but no
commit message or code comment states what alternative was being weighed against it.

## Related Rules
- rules/architecture.md
- rules/cubits.md
- rules/anti-patterns.md (#6, #8)

## Related Concepts
- [[AbleConfigs]]
- [[ExceptionHandler]]
- [[AbleCubit]]
