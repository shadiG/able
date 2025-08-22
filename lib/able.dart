/// The main library for the `able` package.
///
/// This library serves as the entry point for the `able` package,
/// exporting various modules that provide core functionalities.
///
/// It includes:
/// - Common utilities and base classes from `src/common`.
/// - Abstractions and implementations for fetchable data patterns from `src/fetchable`.
/// - Components and utilities for managing progress states from `src/progressable`.
/// - General utility functions and helpers from `src/utils`.
/// - A collection of reusable Flutter widgets from `src/widgets`.
///
/// To use this library, add the `able` package as a dependency in your `pubspec.yaml`
/// and import this file:
/// ```dart
/// import 'package:able/able.dart';
/// ```
library able;

export 'package:able/src/common/export.dart';
export 'package:able/src/fetchable/export.dart';
export 'package:able/src/progressable/export.dart';
export 'package:able/src/utils/export.dart';
export 'package:able/src/widgets/export.dart';
