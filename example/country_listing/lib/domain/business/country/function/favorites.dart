import 'package:able/able.dart';
import 'package:built_collection/built_collection.dart';
import 'package:country_listing/domain/business/country/country_cubit.dart';
import 'package:country_listing/domain/business/country/function/extension.dart';
import 'package:country_listing/domain/constants.dart';
import 'package:country_listing/domain/exception/country_exception.dart';

extension CountryFavoritesExtension on CountryCubit {
  /// Adds [code] to the favorites, or removes it when already there.
  ///
  /// Errors with [FavoriteLimitReachedException] when adding past
  /// [AppConstants.maxFavorites]. Saves to the repository first, then rebuilds.
  Stream<Progressable> toggleFavorite(String code) => futureAsProgressable(() async {
        final favorites = await favoriteCodes;
        final BuiltSet<String> next;
        if (favorites.contains(code)) {
          next = favorites.rebuild((b) => b.remove(code));
        } else {
          if (favorites.length >= AppConstants.maxFavorites) {
            throw const FavoriteLimitReachedException(AppConstants.maxFavorites);
          }
          next = favorites.rebuild((b) => b.add(code));
        }
        await countryRepository.saveFavoriteCodes(next);
        rebuild(state.rebuild((b) => b..favoriteCodesF = next.asFetchable()));
      });
}
