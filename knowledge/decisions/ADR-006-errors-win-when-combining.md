# ADR-006: Errors take precedence when combining states

## Status
Accepted (0.1.0). Changes the precedence documented before 0.1.0.

## Context
`AbleState.+` (`lib/src/common/able_state.dart`) combines the states of several
[[Fetchable]]/[[Progressable]] values in `combine2F`..`combine9F` and `combine2P`..`combine9P`.
Until 0.1.0 its order was idle, then busy, then error, then success. So when one input failed while
another was still idle or loading, the combined value stayed idle or busy and the error was hidden
until every other input finished. With a live combination this can be indefinitely: in
`example/country_listing`, a failed country load combined with a still-loading favorites list
would show a spinner rather than the error and its Retry button.

The change was made in the 0.1.0 bug-fix pass, at the package owner's request to fix the
"errors are masked when combining" issue.

## Decision
`AbleState.+` returns `error` if either side is `error`; otherwise `idle` if either is `idle`;
otherwise `busy` if either is `busy`; otherwise `success`.

## Consequences
- A combined `Fetchable`/`Progressable` reports a failure as soon as any input fails, so screens
  can render the error (and a retry) without waiting for unrelated inputs.
- A screen that relied on "still loading" while one input had already failed now shows the error
  earlier. This is a behavior change for apps upgrading from 0.0.x.
- Combined with `.hasError` checks (not `.error != null`), `Fetchable.error(null)` is also treated
  as an error everywhere.

## Alternatives
- Keep idle/busy ahead of error (the pre-0.1.0 order): rejected, because it hides failures.
- Make error beat busy but not idle: rejected as harder to explain, with no case found where an
  error should wait for an input that has not even started.

## Related Rules
- rules/state-management.md
- rules/fetchable.md

## Related Concepts
- [[AbleState]]
- [[Fetchable]]
- [[Progressable]]
