import 'package:able/able.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:country_listing/domain/business/country/function/loading.dart';
import 'package:country_listing/domain/entity/country.dart';
import 'package:country_listing/domain/repository/country_repository.dart';

part 'country_cubit.g.dart';

/// Business cubit owning the canonical countries and favorites.
///
/// Created once at the app root. Screens never read it directly: their view
/// cubits mirror the fields they need. Behavior lives in `function/`.
class CountryCubit extends AbleCubit<CountryState> {
  CountryCubit({required this.countryRepository}) : super(CountryState.initial) {
    _initCountries();
    _initFavoriteCodes();
  }

  final CountryRepository countryRepository;

  void _initCountries() => executeSP(loadCountries());

  void _initFavoriteCodes() => executeF(
        () => countryRepository.fetchFavoriteCodes(),
        then: (favoriteCodesF) => rebuild(state.rebuild((b) => b..favoriteCodesF = favoriteCodesF)),
      );
}

abstract class CountryState implements Built<CountryState, CountryStateBuilder> {
  /// Every known country, in repository order.
  Fetchable<BuiltList<Country>> get countriesF;

  /// Codes of the countries the user marked as favorite.
  Fetchable<BuiltSet<String>> get favoriteCodesF;

  CountryState._();

  factory CountryState([void Function(CountryStateBuilder) updates]) = _$CountryState;

  static CountryState get initial => CountryState(
        (b) => b
          ..countriesF = Fetchable.idle()
          ..favoriteCodesF = Fetchable.idle(),
      );
}
