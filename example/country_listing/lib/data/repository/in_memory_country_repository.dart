import 'package:built_collection/built_collection.dart';
import 'package:country_listing/data/source/countries_data.dart';
import 'package:country_listing/domain/entity/country.dart';
import 'package:country_listing/domain/exception/country_exception.dart';
import 'package:country_listing/domain/repository/country_repository.dart';

/// A [CountryRepository] backed by [countriesData], with simulated latency.
///
/// [failuresBeforeSuccess] makes the first loads fail, so the example can show
/// the error state and a retry.
class InMemoryCountryRepository implements CountryRepository {
  InMemoryCountryRepository({
    this.latency = const Duration(milliseconds: 800),
    int failuresBeforeSuccess = 0,
  }) : _remainingFailures = failuresBeforeSuccess;

  final Duration latency;
  int _remainingFailures;
  BuiltSet<String> _favoriteCodes = BuiltSet();

  @override
  Future<BuiltList<Country>> fetchCountries() async {
    await Future<void>.delayed(latency);
    if (_remainingFailures > 0) {
      _remainingFailures--;
      throw const CountryLoadException('Could not reach the country service. Please try again.');
    }
    return countriesData;
  }

  @override
  Future<BuiltSet<String>> fetchFavoriteCodes() async {
    await Future<void>.delayed(latency);
    return _favoriteCodes;
  }

  @override
  Future<void> saveFavoriteCodes(BuiltSet<String> codes) async {
    await Future<void>.delayed(latency ~/ 4);
    _favoriteCodes = codes;
  }
}
