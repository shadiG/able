import 'package:able/able.dart';
import 'package:country_listing/data/repository/in_memory_country_repository.dart';
import 'package:country_listing/data/source/countries_data.dart';
import 'package:country_listing/domain/business/country/country_cubit.dart';
import 'package:country_listing/domain/business/country/function/extension.dart';
import 'package:country_listing/domain/entity/region.dart';
import 'package:country_listing/presentation/view/country_list/cubit/country_list_view_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(Able.initialize);

  late CountryCubit countryCubit;
  late CountryListViewCubit cubit;

  /// Lets the in-memory repository and the derived stream settle.
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

  List<String> visibleCodes() => cubit.state.visibleCountriesF.data.map((item) => item.country.code).toList();

  setUp(() async {
    countryCubit = CountryCubit(countryRepository: InMemoryCountryRepository(latency: Duration.zero));
    await countryCubit.countries;
    cubit = CountryListViewCubit(countryCubit: countryCubit);
    await settle();
  });

  tearDown(() async {
    await cubit.close();
    await countryCubit.close();
  });

  test('shows every country sorted by name', () {
    final names = cubit.state.visibleCountriesF.data.map((item) => item.country.name).toList();

    expect(names.length, countriesData.length);
    expect(names, [...names]..sort());
  });

  test('search matches name or capital, case-insensitively', () async {
    cubit.search('LOMÉ');
    await settle();
    expect(visibleCodes(), ['TG']);

    cubit.search('gha');
    await settle();
    expect(visibleCodes(), ['GH']);
  });

  test('region and favorites filters combine', () async {
    cubit.selectRegion(Region.oceania);
    await settle();
    expect(visibleCodes(), ['AU', 'FJ', 'NZ']);

    cubit.toggleFavorite('NZ');
    await settle();
    cubit.setOnlyFavorites(true);
    await settle();
    expect(visibleCodes(), ['NZ']);
    expect(cubit.state.visibleCountriesF.data.single.isFavorite, isTrue);
  });
}
