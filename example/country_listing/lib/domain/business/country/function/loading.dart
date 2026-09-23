import 'package:able/able.dart';
import 'package:country_listing/domain/business/country/country_cubit.dart';

extension CountryLoadingExtension on CountryCubit {
  /// Loads countries and mirrors every step into `countriesF`.
  ///
  /// While reloading, `countriesF` keeps the countries already loaded
  /// (`toRefreshing`), so screens can keep showing them. A failure is stored
  /// on `countriesF` so screens can render it, and is rethrown so the
  /// caller's `Progressable` reports it as well.
  Stream<Progressable> loadCountries() => futureAsProgressable(() async {
        rebuild(state.rebuild((b) => b..countriesF = state.countriesF.toRefreshing()));
        try {
          final countries = await countryRepository.fetchCountries();
          rebuild(state.rebuild((b) => b..countriesF = countries.asFetchable()));
        } catch (e) {
          rebuild(state.rebuild((b) => b..countriesF = Fetchable.error(e)));
          rethrow;
        }
      });
}
