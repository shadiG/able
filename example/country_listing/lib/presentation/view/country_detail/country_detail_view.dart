import 'package:able/able.dart';
import 'package:country_listing/domain/business/country/country_cubit.dart';
import 'package:country_listing/domain/entity/country.dart';
import 'package:country_listing/presentation/extension/int_extension.dart';
import 'package:country_listing/presentation/extension/region_extension.dart';
import 'package:country_listing/presentation/view/country_detail/cubit/country_detail_view_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CountryDetailView extends StatelessWidget {
  const CountryDetailView({required this.countryCode, super.key});

  final String countryCode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CountryDetailViewCubit(
        countryCubit: context.read<CountryCubit>(),
        countryCode: countryCode,
      ),
      child: ProgressablesResultPresenter<CountryDetailViewCubit, CountryDetailViewState>(
        presenters: [
          ProgressableResultPresenter(
            progressable: (s) => s.toggleFavoriteP,
            onError: (e) => ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text('$e'))),
          ),
        ],
        child: const _CountryDetailContent(),
      ),
    );
  }
}

class _CountryDetailContent extends StatelessWidget {
  const _CountryDetailContent();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CountryDetailViewCubit>();
    final countryF = context.select((CountryDetailViewCubit c) => c.state.countryF);
    final isFavoriteF = context.select((CountryDetailViewCubit c) => c.state.isFavoriteF);
    final toggleFavoriteP = context.select((CountryDetailViewCubit c) => c.state.toggleFavoriteP);

    return Scaffold(
      appBar: AppBar(
        title: FetchableWidget(
          fetchable: countryF,
          buildBusy: (context) => const SizedBox.shrink(),
          buildError: (context, error) => const SizedBox.shrink(),
          buildSuccess: (context, country) => Text(country.name),
        ),
        actions: [
          FetchableWidget(
            fetchable: isFavoriteF,
            buildBusy: (context) => const SizedBox.shrink(),
            buildSuccess: (context, isFavorite) => IconButton(
              onPressed: toggleFavoriteP.busy ? null : cubit.toggleFavorite,
              tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
              icon: Icon(
                isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isFavorite ? Colors.amber.shade700 : null,
              ),
            ),
          ),
        ],
      ),
      // Owns the screen's main content, so the global loading/error widgets
      // from `Able.initialize` are the right fallback here.
      body: FetchableWidget(
        fetchable: countryF,
        buildSuccess: (context, country) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(child: Text(country.flag, style: const TextStyle(fontSize: 96))),
            const SizedBox(height: 16),
            _InfoRow(label: 'Capital', value: country.capital),
            _InfoRow(label: 'Region', value: country.region.label),
            _InfoRow(label: 'Population', value: country.population.withThousandsSeparators),
            _InfoRow(label: 'Code', value: country.code),
            const SizedBox(height: 24),
            Text('More in ${country.region.label}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const _Neighbours(),
          ],
        ),
      ),
    );
  }
}

class _Neighbours extends StatelessWidget {
  const _Neighbours();

  @override
  Widget build(BuildContext context) {
    final neighboursF = context.select((CountryDetailViewCubit c) => c.state.neighboursF);

    return FetchableWidget(
      fetchable: neighboursF,
      buildBusy: (context) => const LinearProgressIndicator(),
      buildSuccess: (context, neighbours) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final Country neighbour in neighbours)
            ActionChip(
              avatar: Text(neighbour.flag),
              label: Text(neighbour.name),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CountryDetailView(countryCode: neighbour.code),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.outline))),
          Text(value, style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}
