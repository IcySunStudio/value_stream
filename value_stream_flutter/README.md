## About
Simple and easy to use set of basic streams with direct access to the **latest emitted value**.

### Stream
- Use `DataStream` for simple data stream, without error handling (provides direct access to latest value)
- Use `EventStream` for a stream that needs error handling, with access to latest emitted value or error.

### StreamBuilder
Provides handy adapted `StreamBuilder`s
- `DataStreamBuilder` for a `DataStream`.
- `EventStreamBuilder` for a `EventStream`.

**Package in development: documentation, examples and more to come.**

## Motivation
Simplify Flutter reactive programming with basic streams that handle latest emited value, and avoid un-needed `Snapshot` objects when possible.

## Features
- No dependencies other than Flutter
- Simple code

## Getting started

To install this package, follow this [instruction](https://pub.dev/packages/value_stream/install).

## Usage

TODO: finish Include short and useful examples for package users. Add longer examples to `/example` folder.

```dart
const like = 'sample';
```

## Alternatives
You can also look at theses packages that may better match your needs.
- The *stream_with_value* package, but uses single-subscription stream instead of broadcast stream.
- The *sstream* package, but doesn't have an error-less stream like `DataStream`. 
