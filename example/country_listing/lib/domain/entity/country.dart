import 'package:built_value/built_value.dart';
import 'package:country_listing/domain/entity/region.dart';

part 'country.g.dart';

/// A country shown in the listing.
abstract class Country implements Built<Country, CountryBuilder> {
  /// ISO 3166-1 alpha-2 code, e.g. `TG`. Unique per country.
  String get code;

  /// Common English name.
  String get name;

  /// Capital city.
  String get capital;

  /// Continent-level region.
  Region get region;

  /// Approximate population.
  int get population;

  /// The flag emoji, built from the two regional-indicator symbols of [code].
  @memoized
  String get flag => String.fromCharCodes(
        code.toUpperCase().codeUnits.map((unit) => 0x1F1E6 + unit - 0x41),
      );

  Country._();

  factory Country([void Function(CountryBuilder) updates]) = _$Country;
}
