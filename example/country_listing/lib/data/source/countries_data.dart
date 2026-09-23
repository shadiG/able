import 'package:built_collection/built_collection.dart';
import 'package:country_listing/domain/entity/country.dart';
import 'package:country_listing/domain/entity/region.dart';

/// Seed data for the in-memory repository. Populations are approximate.
final BuiltList<Country> countriesData = BuiltList.of([
  for (final (code, name, capital, region, population) in _rows)
    Country(
      (b) => b
        ..code = code
        ..name = name
        ..capital = capital
        ..region = region
        ..population = population,
    ),
]);

const _rows = <(String, String, String, Region, int)>[
  ('TG', 'Togo', 'Lomé', Region.africa, 9053799),
  ('GH', 'Ghana', 'Accra', Region.africa, 34121985),
  ('NG', 'Nigeria', 'Abuja', Region.africa, 223804632),
  ('BJ', 'Benin', 'Porto-Novo', Region.africa, 13712828),
  ('CI', "Côte d'Ivoire", 'Yamoussoukro', Region.africa, 28873034),
  ('SN', 'Senegal', 'Dakar', Region.africa, 17763163),
  ('KE', 'Kenya', 'Nairobi', Region.africa, 55100586),
  ('EG', 'Egypt', 'Cairo', Region.africa, 112716598),
  ('MA', 'Morocco', 'Rabat', Region.africa, 37840044),
  ('ZA', 'South Africa', 'Pretoria', Region.africa, 60414495),
  ('US', 'United States', 'Washington, D.C.', Region.americas, 334914895),
  ('CA', 'Canada', 'Ottawa', Region.americas, 40097761),
  ('MX', 'Mexico', 'Mexico City', Region.americas, 128455567),
  ('BR', 'Brazil', 'Brasília', Region.americas, 216422446),
  ('AR', 'Argentina', 'Buenos Aires', Region.americas, 45773884),
  ('CL', 'Chile', 'Santiago', Region.americas, 19629590),
  ('CO', 'Colombia', 'Bogotá', Region.americas, 52085168),
  ('CN', 'China', 'Beijing', Region.asia, 1410710000),
  ('IN', 'India', 'New Delhi', Region.asia, 1428627663),
  ('JP', 'Japan', 'Tokyo', Region.asia, 124516650),
  ('KR', 'South Korea', 'Seoul', Region.asia, 51712619),
  ('ID', 'Indonesia', 'Jakarta', Region.asia, 277534122),
  ('VN', 'Vietnam', 'Hanoi', Region.asia, 98858950),
  ('FR', 'France', 'Paris', Region.europe, 68170228),
  ('DE', 'Germany', 'Berlin', Region.europe, 84482267),
  ('IT', 'Italy', 'Rome', Region.europe, 58761146),
  ('ES', 'Spain', 'Madrid', Region.europe, 48373336),
  ('GB', 'United Kingdom', 'London', Region.europe, 68350000),
  ('PT', 'Portugal', 'Lisbon', Region.europe, 10467366),
  ('SE', 'Sweden', 'Stockholm', Region.europe, 10540886),
  ('AU', 'Australia', 'Canberra', Region.oceania, 26638544),
  ('NZ', 'New Zealand', 'Wellington', Region.oceania, 5223100),
  ('FJ', 'Fiji', 'Suva', Region.oceania, 936375),
];
