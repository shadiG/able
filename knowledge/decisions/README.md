# Architecture Decision Records

This directory records decisions about the `able` package's design that are grounded in actual
evidence from this repository — either an explicit rationale in `README.md`, or a traceable
commit (message + diff) in `git log`. Where the repository does not contain enough evidence to say
*why* something was decided, the ADR says so explicitly ("Not documented in the repository")
instead of inventing a plausible-sounding rationale.

## Index

| ADR | Title | Status |
|---|---|---|
| [ADR-001](ADR-001-stream-based-async-state.md) | Async state is a value type carried over a `Stream` | Accepted |
| [ADR-002](ADR-002-separate-fetchable-progressable-types.md) | `Fetchable`/`Progressable` are separate types | Accepted |
| [ADR-003](ADR-003-dynamic-typed-errors.md) | Error payloads are typed `dynamic` | Accepted |
| [ADR-004](ADR-004-centralized-exception-handling.md) | Centralized `ExceptionHandler` + `Able.initialize` | Accepted |
| [ADR-005](ADR-005-rebuild-alias-for-emit.md) | `rebuild()` as the sanctioned alias for `emit()` | Accepted |

## What is *not* here

No ADR exists for: the `combine7F`/`combine8F`/`combine9F` state-summation bug (a defect, not a
decision — see `rules/fetchable.md` and `rules/anti-patterns.md` #7), the two `ExceptionHandler`
defects documented in `knowledge/concepts/ExceptionHandler.md` (also defects, not decisions), the
default `takeOnce: true` (no repository evidence for why `true` was chosen over `false`), or the
[[BusinessCubit]]/[[ViewCubit]] consuming-app conventions (real, evidenced patterns, but not
package-level decisions with a traceable rationale in this repository).

Marking something as "not enough evidence for an ADR" is intentional, not an oversight — see
`../../SKILL.md`'s authority rules.
