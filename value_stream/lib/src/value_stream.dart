import 'dart:async';

/// Whether the specified type is nullable.
bool isNullable<T>() => null is T;

/// Abstract read-only base for a broadcast [Stream] with access to the latest emitted value.
abstract class ValueStreamView<T> {
  /// The broadcast stream of values.
  Stream<T> get stream;

  /// Latest emitted value, or null if no value is available yet.
  T? get valueOrNull;

  /// Adds a subscription to this stream.
  ///
  /// Returns a [StreamSubscription] which handles events from this stream using
  /// the provided [onData], [onError] and [onDone] handlers.
  StreamSubscription<T> listen(
    void Function(T data)? onData, {
    Function? onError,
    void Function()? onDone,
  }) => stream.listen(onData, onError: onError, onDone: onDone);

  /// The first element of this stream.
  /// Returns the last emitted value if available, or waits for the first element.
  /// May throw if the first value is an error.
  Future<T> get first;

  /// Waits for the next element emitted by this stream, and returns it.
  /// If the stream emits an error, it will be propagated to the returned future.
  /// If the stream is closed before any data is emitted, it will throw a [StateError].
  Future<T> get next {
    final completer = Completer<T>();
    StreamSubscription<T>? subscription;
    subscription = stream.listen(
      (data) { completer.complete(data); subscription?.cancel(); },
      onError: (e, s) { completer.completeError(e, s); subscription?.cancel(); },
      onDone: () {
        completer.completeError(StateError('Stream closed before any data was emitted'));
        subscription?.cancel();
      },
    );
    return completer.future;
  }
}

/// A read-only broadcast [Stream] view with guaranteed access to the latest value.
/// Does NOT handle errors — use [EventStreamView] if error handling is needed.
///
/// Instances of this class are returned by [DataStream.map] and [DataStreamView.map].
/// They use a lazy subscription to the source stream and automatically close when
/// the source closes — no explicit disposal is required.
class DataStreamView<T> extends ValueStreamView<T> {
  DataStreamView._(T value, StreamController<T> controller)
      : _value = value,
        _controller = controller;

  T _value;
  final StreamController<T> _controller;

  /// Latest emitted value. Always available.
  T get value => _value;

  @override
  T get valueOrNull => _value;

  /// Always true — [DataStreamView] always has a value.
  bool get hasValue => true;

  @override
  Stream<T> get stream => _controller.stream;

  /// Whether the stream is closed.
  bool get isClosed => _controller.isClosed;

  /// Always returns the current [value] immediately, since [DataStreamView] always has a value.
  @override
  Future<T> get first => Future.value(_value);

  /// Returns a new read-only [DataStreamView] that applies [convert] to each value.
  ///
  /// The returned view uses a **lazy subscription**: it only subscribes to this
  /// stream when the first listener attaches, and unsubscribes when the last
  /// listener leaves. It automatically closes when this stream closes.
  DataStreamView<R> map<R>(R Function(T value) convert) {
    StreamSubscription<T>? subscription;
    late final DataStreamView<R> result;
    late final StreamController<R> newController;

    newController = StreamController<R>.broadcast(
      onListen: () {
        subscription = _controller.stream.listen(
          (data) {
            final mapped = convert(data);
            result._value = mapped;
            newController.add(mapped);
          },
          onDone: newController.close,
        );
      },
      onCancel: () {
        subscription?.cancel();
        subscription = null;
      },
    );

    result = DataStreamView._(convert(_value), newController);
    return result;
  }
}

/// A broadcast [Stream] with guaranteed access to the latest emitted value.
/// Does NOT handle errors — use [EventStream] if error handling is needed.
class DataStream<T> extends DataStreamView<T> {
  DataStream(T initialValue)
      : super._(initialValue, StreamController<T>.broadcast());

  /// Creates a [DataStream] that forwards values from [stream].
  /// Values can also be emitted manually via [add].
  /// This [DataStream] will NOT be closed when [stream] is done; only the
  /// internal subscription is cancelled when this [DataStream] is closed.
  /// If [onError] is provided, it is called on errors from [stream];
  /// otherwise errors are ignored.
  DataStream.fromStream(Stream<T> stream, T initialValue, {Function? onError})
      : super._(initialValue, StreamController<T>.broadcast()) {
    _fromStreamSubscription = stream.listen(add, onError: onError ?? (e) {});
  }

  StreamSubscription<T>? _fromStreamSubscription;

  /// Push [data] to the stream.
  /// Ignored (returns false) if [skipIfClosed] is true and the stream is closed.
  /// Ignored (returns false) if [skipSame] is true and [data] == [value].
  /// Ignored (returns false) if [skipNull] is true and [data] is null.
  /// Returns true if [data] was emitted.
  bool add(T data, {bool skipIfClosed = false, bool skipSame = false, bool skipNull = false}) {
    if (skipIfClosed && _controller.isClosed) return false;
    if (skipSame && data == _value) return false;
    if (skipNull && data == null) return false;

    _value = data;
    _controller.add(data);
    return true;
  }

  /// Returns a new [DataStreamView] of type [T?].
  /// Values that satisfy [test] are forwarded as-is; values that do not are replaced with null.
  DataStreamView<T?> where(bool Function(T value) test) {
    final result = DataStream<T?>(test(_value) ? _value : null);
    _controller.stream.listen(
      (data) => result.add(test(data) ? data : null),
      onDone: result.close,
    );
    return result;
  }

  /// Returns this stream as its read-only [DataStreamView] interface.
  /// Useful for exposing a read-only view to external consumers.
  DataStreamView<T> get asView => this;

  /// Close the stream. After that, calls to [add] are no longer allowed.
  Future<void> close() {
    _fromStreamSubscription?.cancel();
    _fromStreamSubscription = null;
    return _controller.close();
  }
}

/// A read-only broadcast [Stream] view with access to the latest emitted value
/// or error.
///
/// Instances of this class are returned by [EventStream.map] and [EventStreamView.map].
/// They use a lazy subscription to the source stream and automatically close when
/// the source closes — no explicit disposal is required.
class EventStreamView<T> extends ValueStreamView<T> {
  EventStreamView._(EventSnapshot<T> snapshot, StreamController<T> controller)
      : _snapshot = snapshot,
        _controller = controller;

  EventSnapshot<T> _snapshot;
  final StreamController<T> _controller;

  /// Latest emitted value, or null if no value has been emitted yet or if the
  /// last event was an error.
  @override
  T? get valueOrNull => _snapshot.value;

  /// Whether a data value (not an error) has been emitted.
  /// Distinguishes "no value yet" from "current value is null".
  bool get hasValue => _snapshot.hasValue;

  /// Latest emitted error, or null if the last event was not an error.
  Object? get error => _snapshot.error;

  /// Whether the last emitted event was an error.
  bool get hasError => _snapshot.hasError;

  @override
  Stream<T> get stream => _controller.stream;

  /// Whether the stream is closed.
  bool get isClosed => _controller.isClosed;

  @override
  Future<T> get first => _snapshot.hasValue ? Future.value(_snapshot.value as T) : stream.first;

  /// Returns a new read-only [EventStreamView] that applies [convert] to each
  /// data value. Errors are forwarded as-is.
  ///
  /// The returned view uses a **lazy subscription**: it only subscribes to this
  /// stream when the first listener attaches, and unsubscribes when the last
  /// listener leaves. It automatically closes when this stream closes.
  EventStreamView<R> map<R>(R Function(T value) convert) {
    StreamSubscription<T>? subscription;
    late final EventStreamView<R> result;
    late final StreamController<R> newController;

    newController = StreamController<R>.broadcast(
      onListen: () {
        subscription = _controller.stream.listen(
          (data) {
            final mapped = convert(data);
            result._snapshot = EventSnapshot.withData(mapped);
            newController.add(mapped);
          },
          onError: (error, stackTrace) {
            result._snapshot = EventSnapshot.withError(error, stackTrace as StackTrace?);
            newController.addError(error, stackTrace as StackTrace?);
          },
          onDone: newController.close,
        );
      },
      onCancel: () {
        subscription?.cancel();
        subscription = null;
      },
    );

    final initialSnapshot = _snapshot.hasValue
        ? EventSnapshot<R>.withData(convert(_snapshot.value as T))
        : EventSnapshot<R>.nothing();

    result = EventStreamView._(initialSnapshot, newController);
    return result;
  }
}

/// A broadcast [Stream] with access to the latest emitted value or error.
class EventStream<T> extends EventStreamView<T> {
  EventStream([T? initialValue])
      : super._(
          (initialValue != null || isNullable<T>())
              ? EventSnapshot<T>.withData(initialValue as T)
              : EventSnapshot<T>.nothing(),
          StreamController<T>.broadcast(),
        );

  /// Creates an [EventStream] that forwards events from [stream].
  /// Values can also be emitted manually via [add] or [addError].
  /// This [EventStream] will NOT be closed when [stream] is done; only the
  /// internal subscription is cancelled when this [EventStream] is closed.
  EventStream.fromStream(Stream<T> stream, [T? initialValue])
      : super._(
          (initialValue != null || isNullable<T>())
              ? EventSnapshot<T>.withData(initialValue as T)
              : EventSnapshot<T>.nothing(),
          StreamController<T>.broadcast(),
        ) {
    _fromStreamSubscription = stream.listen(add, onError: addError);
  }

  StreamSubscription<T>? _fromStreamSubscription;

  /// Push [data] to the stream.
  /// Ignored (returns false) if [skipIfClosed] is true and the stream is closed.
  /// Ignored (returns false) if [skipSame] is true and [data] == [valueOrNull].
  /// Ignored (returns false) if [skipNull] is true and [data] is null.
  /// Returns true if [data] was emitted.
  bool add(T data, {bool skipIfClosed = false, bool skipSame = false, bool skipNull = false}) {
    if (skipIfClosed && _controller.isClosed) return false;
    if (skipSame && data == _snapshot.value) return false;
    if (skipNull && data == null) return false;

    _snapshot = EventSnapshot.withData(data);
    _controller.add(data);
    return true;
  }

  /// Sends or enqueues an error event.
  void addError(Object error, [StackTrace? stackTrace]) {
    _snapshot = EventSnapshot.withError(error, stackTrace);
    _controller.addError(error, stackTrace);
  }

  /// Returns a new [EventStreamView] of type [T?].
  /// Values that satisfy [test] are forwarded as-is; values that do not are replaced with null.
  EventStreamView<T?> where(bool Function(T value) test) {
    final current = valueOrNull;
    final result = EventStream<T?>(current != null && test(current) ? current : null);
    _controller.stream.listen(
      (data) => result.add(test(data) ? data : null),
      onError: result.addError,
      onDone: result.close,
    );
    return result;
  }

  /// Returns this stream as its read-only [EventStreamView] interface.
  /// Useful for exposing a read-only view to external consumers.
  EventStreamView<T> get asView => this;

  /// Close the stream. After that, calls to [add] and [addError] are no longer allowed.
  Future<void> close() {
    _fromStreamSubscription?.cancel();
    _fromStreamSubscription = null;
    return _controller.close();
  }
}

class EventSnapshot<T> {
  const EventSnapshot._(this.value, this.hasValue, this.error, this.stackTrace);
  const EventSnapshot.nothing() : this._(null, false, null, null);
  const EventSnapshot.withData(T data) : this._(data, true, null, null);
  const EventSnapshot.withError(Object error, [StackTrace? stackTrace = StackTrace.empty])
      : this._(null, false, error, stackTrace);

  final T? value;
  final bool hasValue;

  final Object? error;
  final StackTrace? stackTrace;
  bool get hasError => error != null;
}
