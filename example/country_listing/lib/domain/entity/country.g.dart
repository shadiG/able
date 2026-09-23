// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Country extends Country {
  @override
  final String code;
  @override
  final String name;
  @override
  final String capital;
  @override
  final Region region;
  @override
  final int population;
  String? __flag;

  factory _$Country([void Function(CountryBuilder)? updates]) =>
      (CountryBuilder()..update(updates))._build();

  _$Country._(
      {required this.code,
      required this.name,
      required this.capital,
      required this.region,
      required this.population})
      : super._();
  @override
  String get flag => __flag ??= super.flag;

  @override
  Country rebuild(void Function(CountryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CountryBuilder toBuilder() => CountryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Country &&
        code == other.code &&
        name == other.name &&
        capital == other.capital &&
        region == other.region &&
        population == other.population;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, capital.hashCode);
    _$hash = $jc(_$hash, region.hashCode);
    _$hash = $jc(_$hash, population.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Country')
          ..add('code', code)
          ..add('name', name)
          ..add('capital', capital)
          ..add('region', region)
          ..add('population', population))
        .toString();
  }
}

class CountryBuilder implements Builder<Country, CountryBuilder> {
  _$Country? _$v;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _capital;
  String? get capital => _$this._capital;
  set capital(String? capital) => _$this._capital = capital;

  Region? _region;
  Region? get region => _$this._region;
  set region(Region? region) => _$this._region = region;

  int? _population;
  int? get population => _$this._population;
  set population(int? population) => _$this._population = population;

  CountryBuilder();

  CountryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _code = $v.code;
      _name = $v.name;
      _capital = $v.capital;
      _region = $v.region;
      _population = $v.population;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Country other) {
    _$v = other as _$Country;
  }

  @override
  void update(void Function(CountryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Country build() => _build();

  _$Country _build() {
    final _$result = _$v ??
        _$Country._(
          code: BuiltValueNullFieldError.checkNotNull(code, r'Country', 'code'),
          name: BuiltValueNullFieldError.checkNotNull(name, r'Country', 'name'),
          capital: BuiltValueNullFieldError.checkNotNull(
              capital, r'Country', 'capital'),
          region: BuiltValueNullFieldError.checkNotNull(
              region, r'Country', 'region'),
          population: BuiltValueNullFieldError.checkNotNull(
              population, r'Country', 'population'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
