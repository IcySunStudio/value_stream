import 'dart:async';

/// [StreamWithValue] implementation that creates a [Stream] from subsequent
/// calls to [add]. This way, [value] is always set to the latest value that has
/// been [add]ed, regardless of whether the [updates] are listened to (in
/// contrast to [StreamWithLatestValue]).
class ValueStream<T> implements Sink<T> {
  final _controller = StreamController<T>.broadcast();
  T _latestValue;

  ValueStream(T initialValue) : _latestValue = initialValue;

  /// Push [data] to the stream.
  /// Ignored if [skipIfClosed] is true and the stream is closed.
  /// Ignored if [skipSame] is true and [data] == [value].
  /// Ignored if [skipNull] is true and [data] is null.
  /// Return true if [value] was added.
  @override
  bool add(T data, {bool skipIfClosed = false, bool skipSame = false, bool skipNull = false}) {
    if (skipIfClosed && _controller.isClosed) return false;
    if (skipSame && data == value) return false;
    if (skipNull && data == null) return false;

    _controller.add(data);
    _latestValue = data;
    return true;
  }

  /// The value associated with the [updates] stream, commonly the latest one.
  /// Be sure to check [loaded] before accessing the value; otherwise it may not
  /// be initialized yet, and accessing it will raise an exception.
  T get value => _latestValue;

  /// Any changes to [value], in the form of a stream.
  /// The current [value] itself typically is not sent upon [Stream.listen] to
  /// [updates], although this detail is implementation defined.
  StreamSubscription<T> listen(void Function(T data)? onData, {void Function()? onDone}) => _controller.stream.listen(onData, onDone: onDone);

  /// Whether the stream is closed for adding more events.
  bool get isClosed => _controller.isClosed;

  /// Close the stream. After that, calls to [add] are no longer allowed.
  @override
  Future<void> close() => _controller.close();
}
