import 'package:able/able.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:country_listing/domain/business/country/country_cubit.dart';
import 'package:country_listing/domain/business/country/function/favorites.dart';
import 'package:country_listing/domain/business/country/function/loading.dart';
import 'package:country_listing/domain/entity/country.dart';
import 'package:country_listing/domain/entity/region.dart';
import 'package:country_listing/domain/exception/country_exception.dart';

part 'country_list_view_cubit.g.dart';

/// One row of the list: a country and whether it is a favorite.
typedef CountryListItem = ({Country country, bool isFavorite});

/// View cubit for the country list screen.
///
/// Mirrors [CountryCubit]'s countries and favorites, owns the screen's filters,
/// and derives [CountryListViewState.visibleCountriesF] from all of them.
class CountryListViewCubit extends AbleCubit<CountryListViewState> {
  CountryListViewCubit({required this.countryCubit}) : super(CountryListViewState.initial) {
    _observeCountries();
    _observeFavoriteCodes();
    _initVisibleCountries();
  }

  final CountryCubit countryCubit;

  void _observeCountries() => executeSF(
        countryCubit.mapFStream((s) => s.countriesF).distinct(),
        then: (countriesF) => rebuild(state.rebuild((b) => b..countriesF = countriesF)),
        takeOnce: false,
      );

  void _observeFavoriteCodes() => executeSF(
        countryCubit.mapFStream((s) => s.favoriteCodesF).distinct(),
        then: (favoriteCodesF) => rebuild(state.rebuild((b) => b..favoriteCodesF = favoriteCodesF)),
        takeOnce: false,
      );

  /// Recomputes the visible rows whenever the data or any filter changes.
  /// `switchMapOnSuccessF` drops a result whose inputs have since changed.
  void _initVisibleCountries() => executeSF(
        combine5FStreams(
          s1: mapFStream((s) => s.countriesF).distinct(),
          s2: mapFStream((s) => s.favoriteCodesF).distinct(),
          s3: mapFStream((s) => s.queryF).distinct(),
          s4: mapFStream((s) => s.regionF).distinct(),
          s5: mapFStream((s) => s.onlyFavoritesF).distinct(),
        ).distinct().switchMapOnSuccessF((data) {
          final (countries, favoriteCodes, query, region, onlyFavorites) = data;
          return futureAsFetchable(() async {
            final needle = query.trim().toLowerCase();
            return countries
                .where((c) => region == null || c.region == region)
                .where((c) => !onlyFavorites || favoriteCodes.contains(c.code))
                .where((c) =>
                    needle.isEmpty ||
                    c.name.toLowerCase().contains(needle) ||
                    c.capital.toLowerCase().contains(needle))
                .map<CountryListItem>((c) => (country: c, isFavorite: favoriteCodes.contains(c.code)))
                .toBuiltList()
                .rebuild((b) => b.sort((a, b) => a.country.name.compareTo(b.country.name)));
          });
        }),
        then: (visibleCountriesF) => rebuild(state.rebuild((b) => b..visibleCountriesF = visibleCountriesF)),
        takeOnce: false,
      );

  void search(String query) => rebuild(state.rebuild((b) => b..queryF = query.asFetchable()));

  void selectRegion(Region? region) => rebuild(state.rebuild((b) => b..regionF = Fetchable<Region?>.success(region)));

  void setOnlyFavorites(bool onlyFavorites) =>
      rebuild(state.rebuild((b) => b..onlyFavoritesF = onlyFavorites.asFetchable()));

  void reload() => executeSP(
        countryCubit.loadCountries(),
        then: (reloadP) => rebuild(state.rebuild((b) => b..reloadP = reloadP)),
      );

  void toggleFavorite(String code) => executeSP(
        countryCubit.toggleFavorite(code),
        then: (toggleFavoriteP) => rebuild(state.rebuild((b) => b..toggleFavoriteP = toggleFavoriteP)),
        isExpectedError: (e) => e is FavoriteLimitReachedException,
      );
}

abstract class CountryListViewState implements Built<CountryListViewState, CountryListViewStateBuilder> {
  /// Mirror of [CountryState.countriesF].
  Fetchable<BuiltList<Country>> get countriesF;

  /// Mirror of [CountryState.favoriteCodesF].
  Fetchable<BuiltSet<String>> get favoriteCodesF;

  /// Text typed in the search field; matches name or capital.
  Fetchable<String> get queryF;

  /// Region filter; `null` shows every region.
  Fetchable<Region?> get regionF;

  /// Whether only favorites are shown.
  Fetchable<bool> get onlyFavoritesF;

  /// The rows to render, after filtering and sorting by name.
  Fetchable<BuiltList<CountryListItem>> get visibleCountriesF;

  /// Progress of a manual reload.
  Progressable get reloadP;

  /// Progress of the last favorite toggle.
  Progressable get toggleFavoriteP;

  CountryListViewState._();

  factory CountryListViewState([void Function(CountryListViewStateBuilder) updates]) = _$CountryListViewState;

  static CountryListViewState get initial => CountryListViewState(
        (b) => b
          ..countriesF = Fetchable.idle()
          ..favoriteCodesF = Fetchable.idle()
          ..queryF = ''.asFetchable()
          ..regionF = Fetchable<Region?>.success(null)
          ..onlyFavoritesF = false.asFetchable()
          ..visibleCountriesF = Fetchable.idle()
          ..reloadP = Progressable.idle()
          ..toggleFavoriteP = Progressable.idle(),
      );
}
