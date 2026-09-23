# AbleCubit

## What it is
`AbleCubit<State> extends Cubit<State>` (`lib/src/utils/able_cubit.dart`) — the base class every
cubit in an `able`-based app extends instead of raw `Cubit`. Adds `rebuild` (an `emit` alias),
`mapFStream`/`mapPStream` (project a field of this cubit's state as a stream others can subscribe
to), `closeWithCubit` (auto-disposing subscriptions via an internal `CompositeSubscription`),
`doIf`, and — via extension methods — `executeF`/`executeSF`/`executeP`/`executeSP` and
`presentF`/`presentP`.

Since 0.2.0 every `execute*` takes a `key:` that cancels the previous call with the same key
(`cancelExecution` cancels without restarting), `executeNextPage` loads pages ([[Paging]]), and
`rebuild`/`presentF`/`presentP` report to the [[AbleObserver]].

## Why it exists
To give every cubit the same, tested way of turning a `Future`/`Stream` into
[[Fetchable]]/[[Progressable]] state, with consistent error routing to [[ExceptionHandler]] and
automatic subscription cleanup — instead of every cubit hand-rolling `StreamSubscription`
management and `try`/`catch` around `emit`. See [[ADR-004-centralized-exception-handling]] for the
error-routing half of this design, and [[ADR-005-rebuild-alias-for-emit]] for the `rebuild()`
naming convention.

## Where it lives
`lib/src/utils/able_cubit.dart`.

## What it depends on
- [[Fetchable]], [[Progressable]] — the values it streams into state.
- [[ExceptionHandler]] — `presentF`/`presentP` forward unexpected errors to it.
- `rxdart` (`CompositeSubscription`, `takeWhileInclusive`), `flutter_bloc`'s `Cubit`.

## What depends on it
- Every cubit in a consuming app (confirmed: 22/22 `AbleCubit` subclasses in the surveyed
  telavi_app codebase; zero raw `Cubit` subclasses).
- [[BusinessCubit]] and [[ViewCubit]] conventions — both extend `AbleCubit`.
- [[ProgressablesResultPresenter]] — its generic type bound is `C extends AbleCubit<S>`.

## Which rules govern it
- `rules/cubits.md` — the full API reference, including the `.distinct()` note.
- `rules/patterns.md` items 2, 3, 4, 9-20.
- `rules/anti-patterns.md` #1, #3, #4, #7, #10.

## Which decisions affect it
- [[ADR-001-stream-based-async-state]]
- [[ADR-004-centralized-exception-handling]] — `presentF`/`presentP`'s error routing.
- [[ADR-005-rebuild-alias-for-emit]]

## Examples of correct usage
See `rules/patterns.md` items 2, 3, 9-20, and the in-repo reference app
`example/country_listing/` (`CountryCubit`, `CountryListViewCubit`, `CountryDetailViewCubit`).

## Common mistakes
See `rules/anti-patterns.md` #1 (`then:` that never calls `rebuild`), #4 (missing
`takeOnce: false`), and `rules/cubits.md`'s `.distinct()` note.
