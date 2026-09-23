## 0.2.0

New features. Each has tests in `test/features_test.dart`; docs are in `rules/patterns.md`
items 21-27.

### Added
* **Keep data while reloading.** A busy or error `Fetchable` can keep an earlier success's data:
  `toRefreshing()`, `keepingDataOf(previous)`, `latestData`, `latestDataOrNull`, `hasLatestData`,
  `refreshing`. `FetchableWidget` and the list widgets render kept data while busy
  (`showLatestDataWhileBusy`, default true). See ADR-007.
* **`when` / `maybeWhen`** on `Fetchable` and `Progressable`, for exhaustive handling of the four
  states.
* **Cancel by key.** `executeF`/`executeSF`/`executeP`/`executeSP` take `key:`; a new call with the
  same key cancels the previous one. `AbleCubit.cancelExecution(key)`.
* **Pagination.** `PagedList<T>`, `PageResult<T>`, `executeNextPage` and
  `FetchablePagedListWidget<T>`, with loading and retry footers.
* **Progress.** `Progressable.busy(progress:)`, `Progressable.progress`, and
  `futureAsProgressableWithProgress`.
* **`ProgressableButton`**, disabled with a spinner (determinate when progress is known) while
  busy; takes a `builder` for app-specific buttons.
* **List widgets.** `separatorBuilder` on `FetchableListWidget`; new `FetchableSliverGrid` and
  `FetchableListView` (a box `ListView`).
* **`withRetry`**: retry a `Future` with exponential backoff and a `retryIf` filter.
* **`combineAllF` / `combineAllP`** and their `*Streams` versions, for any number of inputs.
* **`AbleObserver`**, set with `Able.initialize(observer:)` or `Able.observer`: sees every rebuild
  and every `execute*` error, including whether it was expected.
* **Testing.** `package:able/testing.dart` with matchers (`isSuccessF`, `isRefreshingF`,
  `isErrorP`, ...) and `Able.resetForTest()`.
* **`ExceptionHandler.subscribe`** now returns a function that unsubscribes; `unsubscribe(handler)`.
* **`able_lints`**, a separate analyzer-plugin package: `able_then_without_rebuild`,
  `able_mirror_missing_take_once_false`, `able_mirror_missing_distinct`. See ADR-008.
* CI workflow for the package, `able_lints` and both examples.

### Changed
* `Fetchable` equality and `hashCode` include kept data.
* New dependency: `matcher` (used only by `package:able/testing.dart`).

### Fixed
* `rules/patterns.md` item 6 suggested a `SliverToBoxAdapter` in `FetchableListWidget.buildError`,
  which would nest a sliver inside a sliver; it now says to return a box widget.

## 0.1.0

Bug-fix release. Every fix has a regression test in `test/regression_test.dart`.

### Behavior changes
* `AbleState +` (and so every `combineNF`/`combineNP`) now lets an error take precedence over
  idle and busy, so a failure shows as soon as any input fails instead of waiting for the others.
  See `knowledge/decisions/ADR-006-errors-win-when-combining.md`.
* `executeSP(onSuccessP:)` now starts the second action only after the first succeeds. Before,
  both started at once.
* `Fetchable` equality ignores the type argument: `Fetchable<int?>.success(null)` equals
  `Fetchable<Null>.success(null)`.

### Fixes
* `asFuture` (Fetchable and Progressable) stops listening after an error, so a later success no
  longer throws `Bad state: Future already completed`.
* `Able.initialize(onError:)` is now actually called; `ExceptionHandler()` no longer clears it.
* `presentP` reports errors as `AbleType.progressable` instead of `AbleType.fetchable`.
* `combine7F`, `combine8F` and `combine9F` include `f6` in the combined state.
* `Function().asProgressable()` now calls the function.
* `emptyP` is a getter returning a new stream each time, so it can be listened to more than once.
* `rebuild` does nothing once the cubit is closed, instead of throwing when async work finishes
  after its screen is gone.
* `ProgressablesResultPresenter` subscribes in `initState`, so it no longer misses changes made
  before the first frame ends.
* `Fetchable.error(null)` / `Progressable.error(null)` are handled as errors by the widgets,
  `ProgressablesResultPresenter` and the combinators, instead of throwing.
* `AbleType` is exported, so `handleException` callbacks can name it.

### Added
* `switchMapOnSuccessF`: like `flatMapOnSuccessF`, but a new upstream value cancels the previous
  inner stream, so a slow result for an old input can't overwrite a newer one (search results).
  `flatMapOnSuccessF` is unchanged.

### Removed or deprecated
* Removed `presentF`'s unused `doIf` parameter and `mapPStream`'s unused type parameter.
* Deprecated `Stream.executeF(cubit, ...)` and `Stream.executeP(cubit, ...)`, which ignore the
  stream they are called on. Call `executeF`/`executeP` on the cubit instead.

### Package
* Real `pubspec.yaml` description; SDK constraint `>=3.0.0 <4.0.0`, Flutter `>=3.10.0` (the
  package uses Dart 3 records).

## 0.0.1

* Initial release.
