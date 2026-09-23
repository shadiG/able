// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country_detail_view_cubit.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CountryDetailViewState extends CountryDetailViewState {
  @override
  final Fetchable<Country> countryF;
  @override
  final Fetchable<BuiltList<Country>> neighboursF;
  @override
  final Fetchable<bool> isFavoriteF;
  @override
  final Progressable toggleFavoriteP;

  factory _$CountryDetailViewState(
          [void Function(CountryDetailViewStateBuilder)? updates]) =>
      (CountryDetailViewStateBuilder()..update(updates))._build();

  _$CountryDetailViewState._(
      {required this.countryF,
      required this.neighboursF,
      required this.isFavoriteF,
      required this.toggleFavoriteP})
      : super._();
  @override
  CountryDetailViewState rebuild(
          void Function(CountryDetailViewStateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CountryDetailViewStateBuilder toBuilder() =>
      CountryDetailViewStateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CountryDetailViewState &&
        countryF == other.countryF &&
        neighboursF == other.neighboursF &&
        isFavoriteF == other.isFavoriteF &&
        toggleFavoriteP == other.toggleFavoriteP;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, countryF.hashCode);
    _$hash = $jc(_$hash, neighboursF.hashCode);
    _$hash = $jc(_$hash, isFavoriteF.hashCode);
    _$hash = $jc(_$hash, toggleFavoriteP.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CountryDetailViewState')
          ..add('countryF', countryF)
          ..add('neighboursF', neighboursF)
          ..add('isFavoriteF', isFavoriteF)
          ..add('toggleFavoriteP', toggleFavoriteP))
        .toString();
  }
}

class CountryDetailViewStateBuilder
    implements Builder<CountryDetailViewState, CountryDetailViewStateBuilder> {
  _$CountryDetailViewState? _$v;

  Fetchable<Country>? _countryF;
  Fetchable<Country>? get countryF => _$this._countryF;
  set countryF(Fetchable<Country>? countryF) => _$this._countryF = countryF;

  Fetchable<BuiltList<Country>>? _neighboursF;
  Fetchable<BuiltList<Country>>? get neighboursF => _$this._neighboursF;
  set neighboursF(Fetchable<BuiltList<Country>>? neighboursF) =>
      _$this._neighboursF = neighboursF;

  Fetchable<bool>? _isFavoriteF;
  Fetchable<bool>? get isFavoriteF => _$this._isFavoriteF;
  set isFavoriteF(Fetchable<bool>? isFavoriteF) =>
      _$this._isFavoriteF = isFavoriteF;

  Progressable? _toggleFavoriteP;
  Progressable? get toggleFavoriteP => _$this._toggleFavoriteP;
  set toggleFavoriteP(Progressable? toggleFavoriteP) =>
      _$this._toggleFavoriteP = toggleFavoriteP;

  CountryDetailViewStateBuilder();

  CountryDetailViewStateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _countryF = $v.countryF;
      _neighboursF = $v.neighboursF;
      _isFavoriteF = $v.isFavoriteF;
      _toggleFavoriteP = $v.toggleFavoriteP;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CountryDetailViewState other) {
    _$v = other as _$CountryDetailViewState;
  }

  @override
  void update(void Function(CountryDetailViewStateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CountryDetailViewState build() => _build();

  _$CountryDetailViewState _build() {
    final _$result = _$v ??
        _$CountryDetailViewState._(
          countryF: BuiltValueNullFieldError.checkNotNull(
              countryF, r'CountryDetailViewState', 'countryF'),
          neighboursF: BuiltValueNullFieldError.checkNotNull(
              neighboursF, r'CountryDetailViewState', 'neighboursF'),
          isFavoriteF: BuiltValueNullFieldError.checkNotNull(
              isFavoriteF, r'CountryDetailViewState', 'isFavoriteF'),
          toggleFavoriteP: BuiltValueNullFieldError.checkNotNull(
              toggleFavoriteP, r'CountryDetailViewState', 'toggleFavoriteP'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
