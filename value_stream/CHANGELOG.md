## 2.1.0
* New: `map()` is now declared as an abstract method on `ValueStreamView`, making it callable on base-typed references.
* Fix: `map()` now eagerly re-snapshots the source value/error when the first listener attaches (or when re-listening after all listeners cancelled), so that `value`/`valueOrNull` is never stale after a listen-cycle gap.
* Breaking: `where()` removed from `DataStream` and `EventStream`. The method was inconsistent — it uses a fully-eager (always-on) subscription unlike the lazy `map()`, returns a nullable `T?` type making filtering semantics implicit and surprising, and emits redundant `null` events for consecutive filtered-out values. Filtering is better expressed at the call site (e.g. `map((v) => test(v) ? v : null)`) or by consuming `.stream` directly.

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
