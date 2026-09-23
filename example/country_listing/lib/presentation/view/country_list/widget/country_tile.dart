import 'package:country_listing/domain/entity/country.dart';
import 'package:country_listing/presentation/extension/int_extension.dart';
import 'package:flutter/material.dart';

class CountryTile extends StatelessWidget {
  const CountryTile({
    required this.country,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    super.key,
  });

  final Country country;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Text(country.flag, style: const TextStyle(fontSize: 32)),
      title: Text(country.name),
      subtitle: Text('${country.capital} · ${country.population.withThousandsSeparators} people'),
      trailing: IconButton(
        onPressed: onToggleFavorite,
        tooltip: isFavorite ? 'Remove ${country.name} from favorites' : 'Add ${country.name} to favorites',
        icon: Icon(
          isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
          color: isFavorite ? Colors.amber.shade700 : null,
        ),
      ),
    );
  }
}
