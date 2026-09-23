import 'package:able/able.dart';
import 'package:country_listing/domain/business/country/country_cubit.dart';
import 'package:country_listing/domain/constants.dart';
import 'package:country_listing/presentation/view/country_detail/country_detail_view.dart';
import 'package:country_listing/presentation/view/country_list/cubit/country_list_view_cubit.dart';
import 'package:country_listing/presentation/view/country_list/widget/country_tile.dart';
import 'package:country_listing/presentation/view/country_list/widget/filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CountryListView extends StatefulWidget {
  const CountryListView({super.key});

  @override
  State<CountryListView> createState() => _CountryListViewState();
}

class _CountryListViewState extends State<CountryListView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CountryListViewCubit(countryCubit: context.read<CountryCubit>()),
      child: ProgressablesResultPresenter<CountryListViewCubit, CountryListViewState>(
        presenters: [
          ProgressableResultPresenter(
            progressable: (s) => s.reloadP,
            onSuccess: () => _showMessage('Countries refreshed'),
          ),
          ProgressableResultPresenter(
            progressable: (s) => s.toggleFavoriteP,
            onError: (e) => _showMessage('$e'),
          ),
        ],
        child: _CountryListContent(searchController: _searchController),
      ),
    );
  }
}

class _CountryListContent extends StatelessWidget {
  const _CountryListContent({required this.searchController});

  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CountryListViewCubit>();
    final reloadP = context.select((CountryListViewCubit c) => c.state.reloadP);
    final toggleFavoriteP = context.select((CountryListViewCubit c) => c.state.toggleFavoriteP);
    final visibleCountriesF = context.select((CountryListViewCubit c) => c.state.visibleCountriesF);
    final isWorking = [reloadP, toggleFavoriteP].anyBusy;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Countries'),
        actions: [
          IconButton(
            onPressed: reloadP.busy ? null : cubit.reload,
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: isWorking ? const LinearProgressIndicator() : const SizedBox(height: 4),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: searchController,
                onChanged: cubit.search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search by country or capital',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: FilterBar()),
          const SliverToBoxAdapter(child: _Summary()),
          FetchableListWidget<CountryListItem>(
            fetchable: visibleCountriesF,
            hasScrollBody: false,
            buildItem: (context, item) => CountryTile(
              key: ValueKey(item.country.code),
              country: item.country,
              isFavorite: item.isFavorite,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CountryDetailView(countryCode: item.country.code),
                ),
              ),
              onToggleFavorite: toggleFavoriteP.busy ? null : () => cubit.toggleFavorite(item.country.code),
            ),
            buildEmpty: (context) => const _Message(
              icon: Icons.travel_explore_rounded,
              text: 'No country matches these filters.',
            ),
            buildError: (context, error) => _Message(
              icon: Icons.cloud_off_rounded,
              text: '$error',
              action: FilledButton.tonal(onPressed: cubit.reload, child: const Text('Retry')),
            ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary();

  @override
  Widget build(BuildContext context) {
    final visibleCountriesF = context.select((CountryListViewCubit c) => c.state.visibleCountriesF);
    final countriesF = context.select((CountryListViewCubit c) => c.state.countriesF);
    final favoriteCodesF = context.select((CountryListViewCubit c) => c.state.favoriteCodesF);

    return FetchableWidget(
      fetchable: combine3F(f1: visibleCountriesF, f2: countriesF, f3: favoriteCodesF),
      // The list below already renders the busy and error states.
      buildBusy: (context) => const SizedBox.shrink(),
      buildError: (context, error) => const SizedBox.shrink(),
      buildSuccess: (context, data) {
        final (visible, all, favoriteCodes) = data;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Showing ${visible.length} of ${all.length} · '
            '${favoriteCodes.length}/${AppConstants.maxFavorites} favorites',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 12,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
          Text(text, textAlign: TextAlign.center),
          if (action != null) action!,
        ],
      ),
    );
  }
}
