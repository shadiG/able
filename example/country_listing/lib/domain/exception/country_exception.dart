/// The country list could not be loaded.
class CountryLoadException implements Exception {
  const CountryLoadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// No country exists with [code].
class CountryNotFoundException implements Exception {
  const CountryNotFoundException(this.code);

  final String code;

  @override
  String toString() => 'No country with code $code.';
}

/// The user tried to add a favorite past [limit]. Expected: shown to the user,
/// never reported as a crash.
class FavoriteLimitReachedException implements Exception {
  const FavoriteLimitReachedException(this.limit);

  final int limit;

  @override
  String toString() => 'You can keep at most $limit favorites. Remove one first.';
}
