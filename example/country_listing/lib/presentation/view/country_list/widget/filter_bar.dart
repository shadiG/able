import 'package:able/able.dart';
import 'package:country_listing/domain/entity/region.dart';
import 'package:country_listing/presentation/extension/region_extension.dart';
import 'package:country_listing/presentation/view/country_list/cubit/country_list_view_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Region chips plus a "favorites only" chip.
class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final regionF = context.select((CountryListViewCubit c) => c.state.regionF);
    final onlyFavoritesF = context.select((CountryListViewCubit c) => c.state.onlyFavoritesF);
    final cubit = context.read<CountryListViewCubit>();

    // Both fields only matter together for this one widget, so they are
    // combined here with `combine2F` instead of as a cubit field.
    return FetchableWidget(
      fetchable: combine2F(f1: regionF, f2: onlyFavoritesF),
      buildBusy: (context) => const SizedBox.shrink(),
      buildSuccess: (context, data) {
        final (selectedRegion, onlyFavorites) = data;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            spacing: 8,
            children: [
              FilterChip(
                avatar: const Icon(Icons.star_rounded, size: 18),
                label: const Text('Favorites'),
                selected: onlyFavorites,
                onSelected: cubit.setOnlyFavorites,
              ),
              ChoiceChip(
                label: const Text('All'),
                selected: selectedRegion == null,
                onSelected: (_) => cubit.selectRegion(null),
              ),
              for (final region in Region.values)
                ChoiceChip(
                  label: Text(region.label),
                  selected: selectedRegion == region,
                  onSelected: (_) => cubit.selectRegion(region),
                ),
            ],
          ),
        );
      },
    );
  }
}
