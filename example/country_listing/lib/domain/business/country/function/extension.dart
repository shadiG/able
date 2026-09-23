import 'package:able/able.dart';
import 'package:built_collection/built_collection.dart';
import 'package:country_listing/domain/business/country/country_cubit.dart';
import 'package:country_listing/domain/entity/country.dart';
import 'package:country_listing/domain/exception/country_exception.dart';

extension CountryCubitExtension on CountryCubit {
  /// Resolves once `countriesF` succeeds; waits for an in-flight load.
  Future<BuiltList<Country>> get countries => mapFStream((s) => s.countriesF).asFuture(this);

  /// Resolves once `favoriteCodesF` succeeds; waits for an in-flight load.
  Future<BuiltSet<String>> get favoriteCodes => mapFStream((s) => s.favoriteCodesF).asFuture(this);

  /// The country with [code]. Errors with [CountryNotFoundException].
  Stream<Fetchable<Country>> countryByCode(String code) => futureAsFetchable(() async {
        final all = await countries;
        return all.firstWhere(
          (country) => country.code == code,
          orElse: () => throw CountryNotFoundException(code),
        );
      });

  /// The other countries in [country]'s region, sorted by name.
  Stream<Fetchable<BuiltList<Country>>> neighboursOf(Country country) => futureAsFetchable(() async {
        final all = await countries;
        return all
            .where((c) => c.region == country.region && c.code != country.code)
            .toBuiltList()
            .rebuild((b) => b.sort((a, b) => a.name.compareTo(b.name)));
      });
}
