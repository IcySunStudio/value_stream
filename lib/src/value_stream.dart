import 'dart:async';

/// Abstract base class for a broadcast [Stream] with access to the latest emitted value.
abstract class ValueStream<T> implements Sink<T> {
  ValueStream([T? initialValue]) {
    if (initialValue != null) {
      _setValue(initialValue);
    }
  }

  final _controller = StreamController<T>.broadcast();

  /// Push [data] to the stream.
  /// Ignored if [skipIfClosed] is true and the stream is closed.
  /// Ignored if [skipSame] is true and [data] == [value].
  /// Ignored if [skipNull] is true and [data] is null.
  /// Return true if [value] was added.
  @override
  bool add(T data, {bool skipIfClosed = false, bool skipSame = false, bool skipNull = false}) {
    if (skipIfClosed && _controller.isClosed) return false;
    if (skipSame && data == valueOrNull) return false;
    if (skipNull && data == null) return false;

    _controller.add(data);
    _setValue(data);
    return true;
  }

  /// Set value
  void _setValue(T data);

  /// Latest emitted value, or null if no value is available.
  T? get valueOrNull;

  /// Adds a subscription to this stream.
  ///
  /// Returns a [StreamSubscription] which handles events from this stream using the provided [onData] and [onDone] handlers.
  /// The handlers can be changed on the subscription, but they start out as the provided functions.
  StreamSubscription<T> listen(void Function(T data)? onData, {void Function()? onDone});

  /// Internal stream.
  Stream<T> get innerStream => _controller.stream;

  /// Whether the stream is closed for adding more events.
  bool get isClosed => _controller.isClosed;

  /// Close the stream. After that, calls to [add] are no longer allowed.
  @override
  Future<void> close() => _controller.close();
}

/// A broadcast [Stream] with access to the latest emitted value.
/// Does explicitly NOT handle errors to provide a direct and simple access to the [value].
class DataStream<T> extends ValueStream<T> {
  DataStream(T initialValue) : super(initialValue);

  late T _latestValue;

  @override
  void _setValue(T data) => _latestValue = data;

  @override
  T get valueOrNull => _latestValue;

  /// Latest emitted value.
  T get value => _latestValue;

  @override
  StreamSubscription<T> listen(void Function(T data)? onData, {void Function()? onDone}) => _controller.stream.listen(onData, onDone: onDone);
}

/// A broadcast [Stream] with access to the latest emitted value, with error handling.
class EventStream<T> extends ValueStream<T> {
  EventStream([super.initialValue]);

  EventSnapshot<T> _latestSnapshot = const EventSnapshot.nothing();

  @override
  void _setValue(T data) => _latestSnapshot = EventSnapshot.withData(data);

  /// May be null if no value has been emitted yet, or if last emitted value is an error
  @override
  T? get valueOrNull => _latestSnapshot.value;

  /// Latest emitted error, or null if last emitted value is not an error.
  Object? get error => _latestSnapshot.error;

  /// Whether last emitted value is an error.
  /// In which case [error] is not null.
  bool get hasError => _latestSnapshot.hasError;

  /// Sends or enqueues an error event.
  void addError(Object error, [StackTrace? stackTrace]) {
    _controller.addError(error, stackTrace);
    _latestSnapshot = EventSnapshot.withError(error, stackTrace);
  }

  /// Adds a subscription to this stream.
  ///
  /// Returns a [StreamSubscription] which handles events from this stream using the provided [onData], [onError] and [onDone] handlers.
  /// The handlers can be changed on the subscription, but they start out as the provided functions.
  @override
  StreamSubscription<T> listen(void Function(T data)? onData, {Function? onError, void Function()? onDone}) => _controller.stream.listen(onData, onError: onError, onDone: onDone);
}

class EventSnapshot<T> {
  const EventSnapshot._(this.value, this.hasValue, this.error, this.stackTrace);
  const EventSnapshot.nothing(): this._(null, false, null, null);
  const EventSnapshot.withData(T data): this._(data, true, null, null);
  const EventSnapshot.withError(Object error, [StackTrace? stackTrace = StackTrace.empty]): this._(null, false, error, stackTrace);

  final T? value;
  final bool hasValue;

  final Object? error;
  final StackTrace? stackTrace;
  bool get hasError => error != null;
}
