import 'package:able/able.dart';
import 'package:country_listing/app.dart';
import 'package:country_listing/data/repository/in_memory_country_repository.dart';
import 'package:flutter/material.dart';

void main() {
  Able.initialize(
    loadingWidget: const Center(child: CircularProgressIndicator()),
    errorWidget: (context, error) => Center(child: Text('$error')),
    // Unexpected errors only: anything a call site marks with
    // `isExpectedError` (like the favorites limit) never reaches this.
    handleException: (e, s, type) => debugPrint('Unexpected ${type.name} error: $e\n$s'),
  );
  runApp(
    CountryListingApp(
      // The first load fails on purpose, to show the error state and Retry.
      countryRepository: InMemoryCountryRepository(failuresBeforeSuccess: 1),
    ),
  );
}
