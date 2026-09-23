# Country listing

An example app for `able`: a searchable, filterable country list with favorites and a detail screen.

The first load fails on purpose (`failuresBeforeSuccess: 1` in `main.dart`) so the app shows the error state and a Retry button.

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # only after changing a built_value class
flutter run
flutter test
```

## Layout

```
lib/
  main.dart                        Able.initialize + composition root
  app.dart                         business cubit provided once, above the navigator
  domain/
    entity/                        Country (built_value), Region
    exception/                     domain exceptions (one is an *expected* error)
    repository/                    CountryRepository interface
    business/country/
      country_cubit.dart           CountryCubit + CountryState
      function/                    behavior split into extensions
  data/                            in-memory repository with simulated latency
  presentation/view/
    country_list/                  list screen + CountryListViewCubit
    country_detail/                detail screen + CountryDetailViewCubit
```

## Where each Able feature appears

| Feature | Where |
|---|---|
| `Able.initialize` (global loading/error widgets, `handleException`) | `main.dart` |
| `AbleCubit`, `rebuild`, `built_value` state with a `static initial` | every cubit |
| `executeF` (one-shot future into state) | `CountryCubit._initFavoriteCodes` |
| `futureAsProgressable` / `futureAsFetchable` (business methods return streams) | `function/loading.dart`, `favorites.dart`, `extension.dart` |
| `mapFStream(...).asFuture(this)` (await a resolved value) | `CountryCubitExtension.countries` / `favoriteCodes` |
| Live mirror: `executeSF(..., takeOnce: false)` + `.distinct()` | `CountryListViewCubit._observeCountries` |
| Derived field: `combine5FStreams` + `switchMapOnSuccessF` | `CountryListViewCubit._initVisibleCountries` |
| Chained load: `flatMapOnSuccessF` | `CountryDetailViewCubit._initNeighbours` |
| `mapSuccess` | `CountryDetailViewCubit._observeIsFavorite` |
| `executeSP` + `isExpectedError` | `toggleFavorite` in both view cubits |
| `FetchableListWidget` (sliver, empty/error/busy) | `country_list_view.dart` |
| `FetchableWidget` + widget-level `combine2F` / `combine3F` | `FilterBar`, `_Summary` |
| `buildBusy`/`buildError` suppressed for inline pieces | `_Summary`, detail app bar |
| `[aP, bP].anyBusy` | list app bar progress bar |
| `ProgressablesResultPresenter` (snackbar on success/error) | both views |
| `toRefreshing` / `keepingDataOf` (reload keeps the list on screen) | `loading.dart`, `CountryListViewCubit._initVisibleCountries` |
| `ProgressableButton` | detail screen, `_FavoriteButton` |
| `package:able/testing.dart` matchers | `test/country_cubit_test.dart` |
| `able_lints` analyzer plugin | `analysis_options.yaml` (run `dart analyze` to see its warnings) |

`Able.initialize`'s `onError` isn't set, because each screen already shows its errors in its presenter's own `onError`. Setting both would show every non-ignored error twice.
