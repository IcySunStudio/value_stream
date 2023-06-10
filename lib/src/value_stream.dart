import 'dart:async';

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

  /// TODO doc
  void _setValue(T data);

  /// TODO doc
  /// The value associated with the [updates] stream, commonly the latest one.
  /// Be sure to check [loaded] before accessing the value; otherwise it may not
  /// be initialized yet, and accessing it will raise an exception.
  T? get valueOrNull;

  /// TODO doc
  /// Any changes to [value], in the form of a stream.
  /// The current [value] itself typically is not sent upon [Stream.listen] to
  /// [updates], although this detail is implementation defined.
  StreamSubscription<T> listen(void Function(T data)? onData, {void Function()? onDone});

  /// Access to the inner stream.
  /// This stream will never contains errors because ValueStream explicitly don't handle them.
  /// TODO change so ValueStream extends Stream directly like BehaviorSubject, so it's easier to use ? But Stream has error handling by default, and one goal of ValueStream is to exclude Errors.
  Stream<T> get innerStream => _controller.stream;

  /// Whether the stream is closed for adding more events.
  bool get isClosed => _controller.isClosed;

  /// Close the stream. After that, calls to [add] are no longer allowed.
  @override
  Future<void> close() => _controller.close();
}

/// A broadcast [Stream] with access to the latest emitted value.
/// Does explicitly not handle errors to provide a direct and simple access to the value.
class DataValueStream<T> extends ValueStream<T> {
  DataValueStream(T initialValue) : super(initialValue);

  late T _latestValue;

  @override
  void _setValue(T data) => _latestValue = data;

  @override
  T get valueOrNull => _latestValue;

  T get value => _latestValue;

  /// TODO doc
  /// Any changes to [value], in the form of a stream.
  /// The current [value] itself typically is not sent upon [Stream.listen] to
  /// [updates], although this detail is implementation defined.
  @override
  StreamSubscription<T> listen(void Function(T data)? onData, {void Function()? onDone}) => _controller.stream.listen(onData, onDone: onDone);
}

/// A broadcast [Stream] with access to the latest emitted value, with error handling.
/// TODO doc
/// Optional initialValue
class EventValueStream<T> extends ValueStream<T> {
  EventValueStream([super.initialValue]);

  EventSnapshot<T> _latestSnapshot = const EventSnapshot.nothing();

  @override
  void _setValue(T data) => _latestSnapshot = EventSnapshot.withData(data);

  /// May be null if error
  @override
  T? get valueOrNull => _latestSnapshot.value;

  /// TODO doc
  /// TODO also return stackTrace ?
  Object? get error => _latestSnapshot.error;

  /// TODO doc
  bool get hasError => _latestSnapshot.hasError;

  /// TODO doc
  void addError(Object error, [StackTrace? stackTrace]) {
    _controller.addError(error, stackTrace);
    _latestSnapshot = EventSnapshot.withError(error, stackTrace);
  }

  /// TODO doc
  /// Any changes to [value], in the form of a stream.
  /// The current [value] itself typically is not sent upon [Stream.listen] to
  /// [updates], although this detail is implementation defined.
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
