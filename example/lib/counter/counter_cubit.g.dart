// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'counter_cubit.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CounterModel extends CounterModel {
  @override
  final Fetchable<int> counterF;

  factory _$CounterModel([void Function(CounterModelBuilder)? updates]) =>
      (new CounterModelBuilder()..update(updates))._build();

  _$CounterModel._({required this.counterF}) : super._() {
    BuiltValueNullFieldError.checkNotNull(
        counterF, r'CounterModel', 'counterF');
  }

  @override
  CounterModel rebuild(void Function(CounterModelBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CounterModelBuilder toBuilder() => new CounterModelBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CounterModel && counterF == other.counterF;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, counterF.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CounterModel')
          ..add('counterF', counterF))
        .toString();
  }
}

class CounterModelBuilder
    implements Builder<CounterModel, CounterModelBuilder> {
  _$CounterModel? _$v;

  Fetchable<int>? _counterF;
  Fetchable<int>? get counterF => _$this._counterF;
  set counterF(Fetchable<int>? counterF) => _$this._counterF = counterF;

  CounterModelBuilder();

  CounterModelBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _counterF = $v.counterF;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CounterModel other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$CounterModel;
  }

  @override
  void update(void Function(CounterModelBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CounterModel build() => _build();

  _$CounterModel _build() {
    final _$result = _$v ??
        new _$CounterModel._(
            counterF: BuiltValueNullFieldError.checkNotNull(
                counterF, r'CounterModel', 'counterF'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
