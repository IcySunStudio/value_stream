Lightweight set of streams with direct access to the **latest emitted value**.

See [value_stream_flutter](https://pub.dev/packages/value_stream_flutter) for Flutter widgets that use these streams.

**Package in development: documentation, examples and more to come.**

## Motivation
Simplify Flutter reactive programming with basic streams that handle latest emitted value, and avoid un-needed `Snapshot` objects when possible.

## Features
- 🚀 Very lightweight and simple code  
- 🧩 Pure dart, no dependencies

It provides two new Streams:
- Use `DataStream` for simple data stream, without error handling (provides direct access to latest value)
- Use `EventStream` for a stream that needs error handling, with access to latest emitted value or error.

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
