# Able Library Documentation

## Introduction
The Able library provides a set of utility classes and functions that simplify data fetching and state management in Flutter applications. It introduces two main concepts: `Fetchable` and `Progressable`, which allow for streamlined handling of data loading, error states, and operations without data.

## Fetchable
The `Fetchable` class is designed to wrap data that needs to be fetched from a remote source or calculated asynchronously. It eliminates the need to declare multiple fields to represent different data fetching states, such as loading, error, and success.

### Why use `Fetchable`?
By utilizing `Fetchable`, you can avoid declaring separate fields for loading, error, and data for each data type you want to fetch. Instead, you can declare a single `Fetchable<DataType>` field and encompass multiple states, including success, error, busy (loading), and idle.

### Factory Functions
The library provides convenient factory functions that take a `Fetchable` object as input and return a corresponding widget representing the current state. This simplifies UI development by encapsulating the logic for rendering loading indicators, error messages, or the fetched data based on the provided `Fetchable` object.

### Error Handling
Errors are not immediately wrapped in a `Fetchable` object when they occur. Instead, error handling is performed at the end of the data flow, where results are subscribed to. This approach allows for taking advantage of `Stream` error handling operators.

### Subscribing to `Fetchable`
When subscribing to a `Fetchable` object, it is recommended to use the provided extension functions `Stream.presentF` or `Stream.presentP`. These functions ensure that errors emitted by a `Stream` are wrapped in a `Fetchable` or `Progressable` object to be shown in the UI. Additionally, you can define a callback function, `isExpectedError`, to determine if an error should be treated as an expected one or not. By default, only the `NoConnectionException` is considered an expected error.

## Progressable
The `Progressable` class is similar to `Fetchable` but is used to represent operations that do not have any resulting data. It is suitable for scenarios where progress tracking or error handling is necessary, but no specific data is fetched or returned.

### Success State
Unlike `Fetchable`, the success state of `Progressable` does not contain any data. It is primarily used for operations that solely focus on performing an action without returning a specific result.

## Wrapping with `Stream<Fetchable<D>>`
To ensure consistent error handling and display of progress indicators or error messages, it is recommended to wrap all data and operations with a `Stream<Fetchable<D>>` before returning them from the domain layer. This way, errors will be represented in the UI, and you can leverage the capabilities of `Stream` error handling operators.

## Example
Consider a "Sign In" route in your application. If the `SignInFailed` error is expected in this scenario, you can filter it out using the `isExpectedError` callback when calling `Stream.presentF` or `Stream.presentP`. Afterwards, you can handle the error on the UI level and display a corresponding message based on the details contained in the `SignInFailed` exception. The exception or error object can be accessed by reading the `Progressable.error` field.

## Summary
The Able library simplifies data fetching and state management in Flutter applications by introducing the `Fetchable` and `Progressable` concepts. By using these classes, you can consolidate multiple data fetching states into a single field, streamline error handling, and provide consistent UI feedback for loading, errors, and operations without data.