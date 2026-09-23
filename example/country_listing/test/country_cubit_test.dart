import 'package:able/able.dart';
import 'package:country_listing/data/repository/in_memory_country_repository.dart';
import 'package:country_listing/data/source/countries_data.dart';
import 'package:country_listing/domain/business/country/country_cubit.dart';
import 'package:country_listing/domain/business/country/function/extension.dart';
import 'package:country_listing/domain/business/country/function/favorites.dart';
import 'package:country_listing/domain/business/country/function/loading.dart';
import 'package:country_listing/domain/constants.dart';
import 'package:country_listing/domain/exception/country_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(Able.initialize);

  CountryCubit createCubit({int failuresBeforeSuccess = 0}) => CountryCubit(
        countryRepository: InMemoryCountryRepository(
          latency: Duration.zero,
          failuresBeforeSuccess: failuresBeforeSuccess,
        ),
      );

  test('loads every country on creation', () async {
    final cubit = createCubit();

    expect(await cubit.countries, countriesData);
    expect(await cubit.favoriteCodes, isEmpty);
    await cubit.close();
  });

  test('stores a load failure on countriesF, and a reload recovers', () async {
    final cubit = createCubit(failuresBeforeSuccess: 1);

    await expectLater(cubit.countries, throwsA(isA<CountryLoadException>()));
    expect(cubit.state.countriesF.hasError, isTrue);

    await cubit.loadCountries().asFuture(cubit);
    expect(cubit.state.countriesF.data, countriesData);
    await cubit.close();
  });

  test('toggleFavorite adds, then removes, a code', () async {
    final cubit = createCubit();

    await cubit.toggleFavorite('TG').asFuture(cubit);
    expect(await cubit.favoriteCodes, {'TG'});

    await cubit.toggleFavorite('TG').asFuture(cubit);
    expect(await cubit.favoriteCodes, isEmpty);
    await cubit.close();
  });

  test('toggleFavorite refuses to add past the limit', () async {
    final cubit = createCubit();
    final codes = countriesData.map((c) => c.code).take(AppConstants.maxFavorites + 1).toList();
    for (final code in codes.take(AppConstants.maxFavorites)) {
      await cubit.toggleFavorite(code).asFuture(cubit);
    }

    await expectLater(
      cubit.toggleFavorite(codes.last).asFuture(cubit),
      throwsA(isA<FavoriteLimitReachedException>()),
    );
    expect((await cubit.favoriteCodes).length, AppConstants.maxFavorites);
    await cubit.close();
  });

  test('countryByCode errors for an unknown code', () async {
    final cubit = createCubit();

    expect((await cubit.countryByCode('GH').asFuture(cubit)).name, 'Ghana');
    await expectLater(
      cubit.countryByCode('XX').asFuture(cubit),
      throwsA(isA<CountryNotFoundException>()),
    );
    await cubit.close();
  });
}
