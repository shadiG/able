# Architecture

`able` is a small Flutter package that sits on top of `flutter_bloc`'s `Cubit` and adds two
immutable async-state wrappers (`Fetchable<D>`, `Progressable`), a `Cubit` subclass with
stream-execution helpers (`AbleCubit`), and a handful of widgets that render those wrappers
directly. It has no domain logic — it's the shared vocabulary every app cubit is written in.

## Package layout

```
lib/
  able.dart                     # barrel: exports everything below
  src/
    common/
      able_config.dart          # Able.initialize() / Able.configs — global loading & error widgets
      able_state.dart           # AbleState enum (idle/busy/success/error) + `+` combinator
      able_type.dart            # AbleType enum (fetchable/progressable) — tags exceptions by origin; exported
      able_utils.dart           # cross-cutting extensions (asFetchable, asProgressable, list helpers)
    fetchable/
      fetchable.dart            # Fetchable<D> sealed-style class hierarchy
      fetchable_utils.dart      # futureAsFetchable, streamAsFetchable, combine2F..combine9F(Streams)
    progressable/
      progressable.dart         # Progressable class hierarchy
      progressable_utils.dart   # futureAsProgressable, combine2P..combine9P(Streams)
    utils/
      able_cubit.dart           # AbleCubit<State> + executeF/executeP/executeSF/executeSP/presentF/presentP
      exception_handler.dart    # ExceptionHandler singleton, HandleException/OnError typedefs
    widgets/
      common.dart                # BuildSuccess/BuildError/BuildBusy/BuildItem/BuildEmpty typedefs
      fetchable_widget.dart       # FetchableWidget<D>
      fetchable_list_widget.dart  # FetchableListWidget<D> (sliver-based)
      progressables_result_presenter.dart # ProgressablesResultPresenter / ProgressableResultPresenter
```

Each `src/<area>/export.dart` re-exports that area's public files; `lib/able.dart` re-exports
every area. Consumers only ever `import 'package:able/able.dart';`.

## Dependency graph

- `bloc` / `flutter_bloc` — `AbleCubit extends Cubit<State>`.
- `rxdart` — `CombineLatestStream` for the `combineNF/PStreams` helpers, `CompositeSubscription`
  for auto-disposing subscriptions, `takeWhileInclusive` for "stop after first success".
- `built_value` / `built_collection` — not used inside `able` itself; declared because consuming
  apps are expected to model their `Fetchable`/`Progressable`-bearing states with `Built` classes
  and `BuiltList` fields (see [[state-management]]).
- No dependency on `dio`/`chopper`/any specific data layer — `able` is transport-agnostic. It only
  cares that async work is exposed as a `Future` or a `Stream`.

## Three layers inside the package

1. **Value types** (`Fetchable`, `Progressable`, `AbleState`) — pure, immutable, no Flutter
   import in `fetchable.dart`/`progressable.dart`/`able_state.dart`. See [[fetchable]].
2. **Execution glue** (`AbleCubit`, `able_cubit.dart` extensions, `futureAsFetchable`,
   `futureAsProgressable`) — turns a `Future`/`Stream` into a stream of value types and pipes it
   into a cubit's `emit`. See [[cubits]].
3. **Presentation** (`FetchableWidget`, `FetchableListWidget`, `ProgressablesResultPresenter`) —
   Flutter widgets that pattern-match on a value type's state and call the right builder/callback.
   Configured globally through `Able.initialize()` (default loading/error widgets, a global
   exception handler) so individual call sites can omit `buildBusy`/`buildError`.

Data flows one direction only: **Future/Stream → `Fetchable`/`Progressable` → `AbleCubit` state →
widget**. Nothing in `able` reaches back into a repository or service; it has no opinion on where
the `Future` comes from.

## Global configuration (`Able`)

`Able.initialize(loadingWidget:, errorWidget:, handleException:, onError:)` is called once in
`main()` before `runApp()`. It is a singleton (`AbleConfigs`) guarded by an assertion — reading
`Able.configs` before `initialize()` throws. `handleException`/`onError` feed the
`ExceptionHandler` singleton (`src/utils/exception_handler.dart`), which is how unexpected errors
raised inside `executeF`/`executeP` reach app-level logging/crash-reporting without every call
site wiring it up individually. See [[anti-patterns]] for what happens when `initialize()` is
skipped or called twice (it's a no-op the second time, with a `debugPrint` warning).

### Fixed defects in the exception-handling path (0.1.0)

Two defects here were fixed in 0.1.0, each with a regression test in `test/regression_test.dart`.
The full history is in `knowledge/concepts/ExceptionHandler.md`.

1. **`Able.configs`'s `onError` callback was never called.** `ExceptionHandler`'s factory
   assigned `onError` even when called with no argument, so every bare `ExceptionHandler()` call
   cleared it. The factory now only replaces `onError` when one is passed.
2. **`presentP` tagged errors `AbleType.fetchable`.** It now passes `AbleType.progressable`.
   `AbleType` is also exported now, so a `handleException` callback can name it.

The `asFuture` keep-listening-after-error defect (see [[cubits]], "One-shot reads") was fixed in
the same release.

## Consuming-app conventions (observed in practice, not enforced by the package)

`able` itself has no opinion on file layout, but the same shape recurs across apps built on it:

```
lib/
  domain/
    business/
      <feature>/
        <feature>_cubit.dart   # class <Feature>Cubit extends AbleCubit<...>, its State
        function/
          <concern>.dart        # extension <Concern>Extension on <Feature>Cubit
  presentation/
    view/
      <area>/<screen>/
        cubit/
          <screen>_view_cubit.dart   # per-screen AbleCubit subscribing to business cubits
        <screen>_view.dart
        widget/
```

Business cubits (`domain/business/**`) are long-lived, app-scoped, and hold canonical data; their
methods live across a `<feature>_cubit.dart` core file plus one `extension on <Feature>Cubit` per
concern under `function/`, rather than one large class. View cubits (`presentation/view/**/cubit`)
are created per screen, take business cubits as dependencies, and mirror whichever business fields
that screen needs via `mapFStream(...).distinct()` + `executeSF(..., takeOnce: false)`, adding
their own screen-local `Fetchable`/`Progressable` fields alongside. See [[patterns]] for the
concrete recipes this layout enables.

## Example apps in this repository

`example/` holds standalone Flutter apps that depend on `able` through `path: ../..`:

- `example/counter/` — the smallest `AbleCubit`: one `Fetchable<int>`.
- `example/country_listing/` — the reference implementation of the conventions above: a
  `CountryCubit` business cubit with `function/` extensions, two view cubits
  (`CountryListViewCubit`, `CountryDetailViewCubit`), a domain repository interface with an
  in-memory data implementation, expected errors, Able's widgets, and cubit and widget tests.

When a rule here or in [[patterns]] is unclear, `example/country_listing/` is the in-repo code to
read. It is kept passing `flutter analyze` and `flutter test`; if you change a rule it
demonstrates, update the example in the same change.

## Related knowledge

- Concepts: [[AbleCubit]], [[AbleConfigs]], [[ExceptionHandler]], [[BusinessCubit]], [[ViewCubit]]
- Decisions: [[ADR-001-stream-based-async-state]], [[ADR-004-centralized-exception-handling]]
- Graph: `knowledge/graph/graph.json` (query `governed_by`/`documented_by` edges targeting
  `rule-architecture`)