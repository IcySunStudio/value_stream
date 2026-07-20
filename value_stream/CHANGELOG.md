## 2.0.0
* BREAKING: Introduced read-only `*View` hierarchy (`ValueStreamView`, `DataStreamView`, `EventStreamView`) separate from writable `*Stream` classes.
* BREAKING: `ValueStream` base class removed; replaced by `ValueStreamView`.
* BREAKING: `innerStream` renamed to `stream`.
* BREAKING: `DataStream`/`EventStream` no longer implement `Sink`.
* New: `map()` operator on `DataStreamView` and `EventStreamView`, returning a read-only `*View`.
* New: `where()` operator on `DataStream` and `EventStream`, returning a nullable read-only `*View`.
* New: `asView` getter on `DataStream` and `EventStream` to expose a read-only `*View` interface.

## 1.1.1
* New: `hasValue` getter on `ValueStream`, `DataStream`, and `EventStream` to distinguish "no value yet" from "current value is null".
* Fix `first` hanging for nullable streams when the current value is `null`.

## 1.1.0
* New `next` getter to await the next event in the stream.

## 1.0.0
* BREAKING: split package in 2, to remove flutter dependency. Widgets of this package are now in the `value_stream_flutter` package.

## 0.2.0
* Add `DataStream.fromStream` constructor

## 0.1.0
* `EventStreamBuilder` now handle `initialError`
* Add `EventStreamBuilder.fromStream` constructor

## 0.0.5
* Add `EventStream.fromStream` constructor

## 0.0.4
* Add `ValueStream.first` getter

## 0.0.3
* Allow `null` stream on `EventStreamBuilder`

## 0.0.2
* Finish first implementation

## 0.0.1
* Initial release.
