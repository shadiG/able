import 'package:built_collection/built_collection.dart';
import 'package:country_listing/domain/entity/country.dart';

/// Source of countries and the user's favorite country codes.
abstract interface class CountryRepository {
  /// All countries. Throws `CountryLoadException` when they can't be loaded.
  Future<BuiltList<Country>> fetchCountries();

  /// The codes of the countries the user marked as favorite.
  Future<BuiltSet<String>> fetchFavoriteCodes();

  /// Replaces the stored favorite codes with [codes].
  Future<void> saveFavoriteCodes(BuiltSet<String> codes);
}
