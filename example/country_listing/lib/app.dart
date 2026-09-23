import 'package:country_listing/domain/business/country/country_cubit.dart';
import 'package:country_listing/domain/repository/country_repository.dart';
import 'package:country_listing/presentation/view/country_list/country_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CountryListingApp extends StatelessWidget {
  const CountryListingApp({required this.countryRepository, super.key});

  final CountryRepository countryRepository;

  @override
  Widget build(BuildContext context) {
    // The business cubit is created once, above the navigator, so every route
    // can hand it to its own view cubit.
    return BlocProvider(
      create: (_) => CountryCubit(countryRepository: countryRepository),
      child: MaterialApp(
        title: 'Countries',
        theme: ThemeData(colorSchemeSeed: Colors.teal),
        home: const CountryListView(),
      ),
    );
  }
}
