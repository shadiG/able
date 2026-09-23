// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country_list_view_cubit.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CountryListViewState extends CountryListViewState {
  @override
  final Fetchable<BuiltList<Country>> countriesF;
  @override
  final Fetchable<BuiltSet<String>> favoriteCodesF;
  @override
  final Fetchable<String> queryF;
  @override
  final Fetchable<Region?> regionF;
  @override
  final Fetchable<bool> onlyFavoritesF;
  @override
  final Fetchable<BuiltList<CountryListItem>> visibleCountriesF;
  @override
  final Progressable reloadP;
  @override
  final Progressable toggleFavoriteP;

  factory _$CountryListViewState(
          [void Function(CountryListViewStateBuilder)? updates]) =>
      (CountryListViewStateBuilder()..update(updates))._build();

  _$CountryListViewState._(
      {required this.countriesF,
      required this.favoriteCodesF,
      required this.queryF,
      required this.regionF,
      required this.onlyFavoritesF,
      required this.visibleCountriesF,
      required this.reloadP,
      required this.toggleFavoriteP})
      : super._();
  @override
  CountryListViewState rebuild(
          void Function(CountryListViewStateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CountryListViewStateBuilder toBuilder() =>
      CountryListViewStateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CountryListViewState &&
        countriesF == other.countriesF &&
        favoriteCodesF == other.favoriteCodesF &&
        queryF == other.queryF &&
        regionF == other.regionF &&
        onlyFavoritesF == other.onlyFavoritesF &&
        visibleCountriesF == other.visibleCountriesF &&
        reloadP == other.reloadP &&
        toggleFavoriteP == other.toggleFavoriteP;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, countriesF.hashCode);
    _$hash = $jc(_$hash, favoriteCodesF.hashCode);
    _$hash = $jc(_$hash, queryF.hashCode);
    _$hash = $jc(_$hash, regionF.hashCode);
    _$hash = $jc(_$hash, onlyFavoritesF.hashCode);
    _$hash = $jc(_$hash, visibleCountriesF.hashCode);
    _$hash = $jc(_$hash, reloadP.hashCode);
    _$hash = $jc(_$hash, toggleFavoriteP.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CountryListViewState')
          ..add('countriesF', countriesF)
          ..add('favoriteCodesF', favoriteCodesF)
          ..add('queryF', queryF)
          ..add('regionF', regionF)
          ..add('onlyFavoritesF', onlyFavoritesF)
          ..add('visibleCountriesF', visibleCountriesF)
          ..add('reloadP', reloadP)
          ..add('toggleFavoriteP', toggleFavoriteP))
        .toString();
  }
}

class CountryListViewStateBuilder
    implements Builder<CountryListViewState, CountryListViewStateBuilder> {
  _$CountryListViewState? _$v;

  Fetchable<BuiltList<Country>>? _countriesF;
  Fetchable<BuiltList<Country>>? get countriesF => _$this._countriesF;
  set countriesF(Fetchable<BuiltList<Country>>? countriesF) =>
      _$this._countriesF = countriesF;

  Fetchable<BuiltSet<String>>? _favoriteCodesF;
  Fetchable<BuiltSet<String>>? get favoriteCodesF => _$this._favoriteCodesF;
  set favoriteCodesF(Fetchable<BuiltSet<String>>? favoriteCodesF) =>
      _$this._favoriteCodesF = favoriteCodesF;

  Fetchable<String>? _queryF;
  Fetchable<String>? get queryF => _$this._queryF;
  set queryF(Fetchable<String>? queryF) => _$this._queryF = queryF;

  Fetchable<Region?>? _regionF;
  Fetchable<Region?>? get regionF => _$this._regionF;
  set regionF(Fetchable<Region?>? regionF) => _$this._regionF = regionF;

  Fetchable<bool>? _onlyFavoritesF;
  Fetchable<bool>? get onlyFavoritesF => _$this._onlyFavoritesF;
  set onlyFavoritesF(Fetchable<bool>? onlyFavoritesF) =>
      _$this._onlyFavoritesF = onlyFavoritesF;

  Fetchable<BuiltList<CountryListItem>>? _visibleCountriesF;
  Fetchable<BuiltList<CountryListItem>>? get visibleCountriesF =>
      _$this._visibleCountriesF;
  set visibleCountriesF(
          Fetchable<BuiltList<CountryListItem>>? visibleCountriesF) =>
      _$this._visibleCountriesF = visibleCountriesF;

  Progressable? _reloadP;
  Progressable? get reloadP => _$this._reloadP;
  set reloadP(Progressable? reloadP) => _$this._reloadP = reloadP;

  Progressable? _toggleFavoriteP;
  Progressable? get toggleFavoriteP => _$this._toggleFavoriteP;
  set toggleFavoriteP(Progressable? toggleFavoriteP) =>
      _$this._toggleFavoriteP = toggleFavoriteP;

  CountryListViewStateBuilder();

  CountryListViewStateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _countriesF = $v.countriesF;
      _favoriteCodesF = $v.favoriteCodesF;
      _queryF = $v.queryF;
      _regionF = $v.regionF;
      _onlyFavoritesF = $v.onlyFavoritesF;
      _visibleCountriesF = $v.visibleCountriesF;
      _reloadP = $v.reloadP;
      _toggleFavoriteP = $v.toggleFavoriteP;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CountryListViewState other) {
    _$v = other as _$CountryListViewState;
  }

  @override
  void update(void Function(CountryListViewStateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CountryListViewState build() => _build();

  _$CountryListViewState _build() {
    final _$result = _$v ??
        _$CountryListViewState._(
          countriesF: BuiltValueNullFieldError.checkNotNull(
              countriesF, r'CountryListViewState', 'countriesF'),
          favoriteCodesF: BuiltValueNullFieldError.checkNotNull(
              favoriteCodesF, r'CountryListViewState', 'favoriteCodesF'),
          queryF: BuiltValueNullFieldError.checkNotNull(
              queryF, r'CountryListViewState', 'queryF'),
          regionF: BuiltValueNullFieldError.checkNotNull(
              regionF, r'CountryListViewState', 'regionF'),
          onlyFavoritesF: BuiltValueNullFieldError.checkNotNull(
              onlyFavoritesF, r'CountryListViewState', 'onlyFavoritesF'),
          visibleCountriesF: BuiltValueNullFieldError.checkNotNull(
              visibleCountriesF, r'CountryListViewState', 'visibleCountriesF'),
          reloadP: BuiltValueNullFieldError.checkNotNull(
              reloadP, r'CountryListViewState', 'reloadP'),
          toggleFavoriteP: BuiltValueNullFieldError.checkNotNull(
              toggleFavoriteP, r'CountryListViewState', 'toggleFavoriteP'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
