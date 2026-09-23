/// Test helpers for code built on `able`: matchers for [Fetchable] and
/// [Progressable], and a way to reset Able's global configuration.
///
/// Import only from tests:
/// ```dart
/// import 'package:able/testing.dart';
///
/// expect(cubit.state.contactsF, isSuccessF(hasLength(3)));
/// expect(cubit.state.saveP, isErrorP(isA<ValidationException>()));
/// ```
library;

import 'package:able/able.dart';
import 'package:matcher/matcher.dart';

export 'package:able/able.dart' show Able;

/// Matches an idle [Fetchable].
const Matcher isIdleF = _FetchableState(AbleState.idle, 'idle');

/// Matches a busy [Fetchable], with or without kept data.
const Matcher isBusyF = _FetchableState(AbleState.busy, 'busy');

/// Matches a busy [Fetchable] that kept earlier data ([Fetchable.refreshing]).
/// With [data], the kept data must also match it.
Matcher isRefreshingF([Object? data]) => _FetchableRefreshing(data == null ? anything : wrapMatcher(data));

/// Matches a successful [Fetchable]; with [data], its data must match it
/// (a value or a matcher).
Matcher isSuccessF([Object? data]) => _FetchableSuccess(data == null ? anything : wrapMatcher(data));

/// Matches an error [Fetchable]; with [error], its error must match it.
Matcher isErrorF([Object? error]) => _FetchableError(error == null ? anything : wrapMatcher(error));

/// Matches an idle [Progressable].
const Matcher isIdleP = _ProgressableState(AbleState.idle, 'idle');

/// Matches a busy [Progressable]; with [progress], its progress must match.
Matcher isBusyP([Object? progress]) => _ProgressableBusy(progress == null ? anything : wrapMatcher(progress));

/// Matches a successful [Progressable].
const Matcher isSuccessP = _ProgressableState(AbleState.success, 'success');

/// Matches an error [Progressable]; with [error], its error must match it.
Matcher isErrorP([Object? error]) => _ProgressableError(error == null ? anything : wrapMatcher(error));

class _FetchableState extends Matcher {
  const _FetchableState(this.state, this.name);

  final AbleState state;
  final String name;

  @override
  bool matches(Object? item, Map matchState) => item is Fetchable && item.state == state;

  @override
  Description describe(Description description) => description.add('a $name Fetchable');
}

class _FetchableSuccess extends Matcher {
  const _FetchableSuccess(this.data);

  final Matcher data;

  @override
  bool matches(Object? item, Map matchState) => item is Fetchable && item.success && data.matches(item.data, matchState);

  @override
  Description describe(Description description) =>
      description.add('a successful Fetchable with data ').addDescriptionOf(data);
}

class _FetchableRefreshing extends Matcher {
  const _FetchableRefreshing(this.data);

  final Matcher data;

  @override
  bool matches(Object? item, Map matchState) =>
      item is Fetchable && item.refreshing && data.matches(item.latestData, matchState);

  @override
  Description describe(Description description) =>
      description.add('a busy Fetchable keeping data ').addDescriptionOf(data);
}

class _FetchableError extends Matcher {
  const _FetchableError(this.error);

  final Matcher error;

  @override
  bool matches(Object? item, Map matchState) => item is Fetchable && item.hasError && error.matches(item.error, matchState);

  @override
  Description describe(Description description) => description.add('an error Fetchable with ').addDescriptionOf(error);
}

class _ProgressableState extends Matcher {
  const _ProgressableState(this.state, this.name);

  final AbleState state;
  final String name;

  @override
  bool matches(Object? item, Map matchState) => item is Progressable && item.state == state;

  @override
  Description describe(Description description) => description.add('a $name Progressable');
}

class _ProgressableBusy extends Matcher {
  const _ProgressableBusy(this.progress);

  final Matcher progress;

  @override
  bool matches(Object? item, Map matchState) =>
      item is Progressable && item.busy && progress.matches(item.progress, matchState);

  @override
  Description describe(Description description) =>
      description.add('a busy Progressable with progress ').addDescriptionOf(progress);
}

class _ProgressableError extends Matcher {
  const _ProgressableError(this.error);

  final Matcher error;

  @override
  bool matches(Object? item, Map matchState) =>
      item is Progressable && item.hasError && error.matches(item.error, matchState);

  @override
  Description describe(Description description) =>
      description.add('an error Progressable with ').addDescriptionOf(error);
}
