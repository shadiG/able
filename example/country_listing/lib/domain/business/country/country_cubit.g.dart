// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country_cubit.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CountryState extends CountryState {
  @override
  final Fetchable<BuiltList<Country>> countriesF;
  @override
  final Fetchable<BuiltSet<String>> favoriteCodesF;

  factory _$CountryState([void Function(CountryStateBuilder)? updates]) =>
      (CountryStateBuilder()..update(updates))._build();

  _$CountryState._({required this.countriesF, required this.favoriteCodesF})
      : super._();
  @override
  CountryState rebuild(void Function(CountryStateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CountryStateBuilder toBuilder() => CountryStateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CountryState &&
        countriesF == other.countriesF &&
        favoriteCodesF == other.favoriteCodesF;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, countriesF.hashCode);
    _$hash = $jc(_$hash, favoriteCodesF.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CountryState')
          ..add('countriesF', countriesF)
          ..add('favoriteCodesF', favoriteCodesF))
        .toString();
  }
}

class CountryStateBuilder
    implements Builder<CountryState, CountryStateBuilder> {
  _$CountryState? _$v;

  Fetchable<BuiltList<Country>>? _countriesF;
  Fetchable<BuiltList<Country>>? get countriesF => _$this._countriesF;
  set countriesF(Fetchable<BuiltList<Country>>? countriesF) =>
      _$this._countriesF = countriesF;

  Fetchable<BuiltSet<String>>? _favoriteCodesF;
  Fetchable<BuiltSet<String>>? get favoriteCodesF => _$this._favoriteCodesF;
  set favoriteCodesF(Fetchable<BuiltSet<String>>? favoriteCodesF) =>
      _$this._favoriteCodesF = favoriteCodesF;

  CountryStateBuilder();

  CountryStateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _countriesF = $v.countriesF;
      _favoriteCodesF = $v.favoriteCodesF;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CountryState other) {
    _$v = other as _$CountryState;
  }

  @override
  void update(void Function(CountryStateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CountryState build() => _build();

  _$CountryState _build() {
    final _$result = _$v ??
        _$CountryState._(
          countriesF: BuiltValueNullFieldError.checkNotNull(
              countriesF, r'CountryState', 'countriesF'),
          favoriteCodesF: BuiltValueNullFieldError.checkNotNull(
              favoriteCodesF, r'CountryState', 'favoriteCodesF'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
