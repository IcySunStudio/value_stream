## 2.0.0
* BREAKING: `add()` no longer has `skipIfClosed` and `skipNull` parameters. Adding to a closed stream is now always ignored (`add()` returns false, `addError()` does nothing) instead of throwing. Replace `skipNull: true` with a null check on the caller side.
* BREAKING: `add()` no longer has a `skipSame` parameter. Pass `distinct: true` to the stream constructor instead, so that values equal (`==`) to the current one are always ignored. Beware that adding the same instance again after mutating it is then ignored too.
* BREAKING: `EventStream`'s initial value is no longer optional. Use `EventStream(value)` for a stream with a value (even `null`), and the new `EventStream.empty()` for a stream with no value yet. Previously, `EventStream<T?>()` started with a `null` value.
* BREAKING: `EventStream.fromStream`'s initial value is now the named `initialValue` parameter. If omitted, the stream has no value until `stream` emits, even for a nullable type.
* New: `distinct` option also applies to values coming from the stream given to `fromStream` constructors.
* Fix `EventStream.addError()` updating its state after emitting the error, unlike `add()`.

## 1.1.1
* New: `hasValue` getter on `ValueStream`, `DataStream`, and `EventStream` to distinguish "no value yet" from "current value is null".
* Fix `first` hanging for nullable streams when the current value is `null`. The check now uses `hasValue` semantics instead of `valueOrNull != null`, correctly distinguishing "no value yet" from "current value is null".

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
