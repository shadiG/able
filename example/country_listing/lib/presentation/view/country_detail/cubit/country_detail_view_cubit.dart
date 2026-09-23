import 'package:able/able.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:country_listing/domain/business/country/country_cubit.dart';
import 'package:country_listing/domain/business/country/function/extension.dart';
import 'package:country_listing/domain/business/country/function/favorites.dart';
import 'package:country_listing/domain/entity/country.dart';
import 'package:country_listing/domain/exception/country_exception.dart';

part 'country_detail_view_cubit.g.dart';

/// View cubit for one country's detail screen.
class CountryDetailViewCubit extends AbleCubit<CountryDetailViewState> {
  CountryDetailViewCubit({required this.countryCubit, required this.countryCode})
      : super(CountryDetailViewState.initial) {
    _initCountry();
    _initNeighbours();
    _observeIsFavorite();
  }

  final CountryCubit countryCubit;
  final String countryCode;

  void _initCountry() => executeSF(
        countryCubit.countryByCode(countryCode),
        then: (countryF) => rebuild(state.rebuild((b) => b..countryF = countryF)),
      );

  /// Chains a second load on the first one's result with `flatMapOnSuccessF`.
  void _initNeighbours() => executeSF(
        countryCubit.countryByCode(countryCode).flatMapOnSuccessF(countryCubit.neighboursOf),
        then: (neighboursF) => rebuild(state.rebuild((b) => b..neighboursF = neighboursF)),
      );

  void _observeIsFavorite() => executeSF(
        countryCubit
            .mapFStream((s) => s.favoriteCodesF)
            .map((favoriteCodesF) => favoriteCodesF.mapSuccess((codes) => codes.contains(countryCode)))
            .distinct(),
        then: (isFavoriteF) => rebuild(state.rebuild((b) => b..isFavoriteF = isFavoriteF)),
        takeOnce: false,
      );

  void toggleFavorite() => executeSP(
        countryCubit.toggleFavorite(countryCode),
        then: (toggleFavoriteP) => rebuild(state.rebuild((b) => b..toggleFavoriteP = toggleFavoriteP)),
        isExpectedError: (e) => e is FavoriteLimitReachedException,
      );
}

abstract class CountryDetailViewState implements Built<CountryDetailViewState, CountryDetailViewStateBuilder> {
  /// The country this screen shows.
  Fetchable<Country> get countryF;

  /// The other countries in the same region.
  Fetchable<BuiltList<Country>> get neighboursF;

  /// Whether the country is a favorite; follows the business cubit live.
  Fetchable<bool> get isFavoriteF;

  /// Progress of the last favorite toggle.
  Progressable get toggleFavoriteP;

  CountryDetailViewState._();

  factory CountryDetailViewState([void Function(CountryDetailViewStateBuilder) updates]) =
      _$CountryDetailViewState;

  static CountryDetailViewState get initial => CountryDetailViewState(
        (b) => b
          ..countryF = Fetchable.idle()
          ..neighboursF = Fetchable.idle()
          ..isFavoriteF = Fetchable.idle()
          ..toggleFavoriteP = Progressable.idle(),
      );
}
