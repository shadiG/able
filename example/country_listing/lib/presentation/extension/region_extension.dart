import 'package:country_listing/domain/entity/region.dart';

extension RegionExtension on Region {
  String get label => switch (this) {
        Region.africa => 'Africa',
        Region.americas => 'Americas',
        Region.asia => 'Asia',
        Region.europe => 'Europe',
        Region.oceania => 'Oceania',
      };
}
