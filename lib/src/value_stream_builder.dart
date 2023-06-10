import 'package:flutter/material.dart';

import 'value_stream.dart';

/// Signature for strategies that build widgets based on provided data
typedef DataWidgetBuilder<T> = Widget Function(BuildContext context, T value);

/// Widget that builds itself based on the latest value a [DataValueStream].
class DataValueStreamBuilder<T> extends StreamBuilderBase<T, T> {
  /// Widget that builds itself based on the latest value a [DataValueStream].
  DataValueStreamBuilder({
    super.key,
    required DataValueStream<T> stream,
    required this.builder,
  }) : initialData = stream.value, super(stream: stream.innerStream);

  /// The data that will be used to create the initial snapshot.
  final T initialData;

  /// The build strategy currently used by this builder.
  /// This builder must only return a widget and should not have any side effects as it may be called multiple times.
  final DataWidgetBuilder<T> builder;

  @override
  T initial() => initialData;

  @override
  T afterData(T current, T data) => data;

  @override
  Widget build(BuildContext context, T currentSummary) => builder(context, currentSummary);
}

typedef EventWidgetBuilder<T> = Widget Function(BuildContext context, EventSnapshot<T> snapshot);

class EventValueStreamBuilder<T> extends StreamBuilderBase<T, EventSnapshot<T>> {
  /// TODO doc
  EventValueStreamBuilder({
    super.key,
    required EventValueStream<T> stream,
    required this.builder,
  }) : initialData = stream.valueOrNull, super(stream: stream.innerStream);

  final T? initialData;

  final EventWidgetBuilder<T> builder;

  @override
  EventSnapshot<T> initial() => initialData == null
      ? EventSnapshot<T>.nothing()
      : EventSnapshot<T>.withData(initialData as T);

  @override
  EventSnapshot<T> afterData(EventSnapshot<T> current, T data) => EventSnapshot<T>.withData(data);

  @override
  EventSnapshot<T> afterError(EventSnapshot<T> current, Object error, StackTrace stackTrace) => EventSnapshot<T>.withError(error, stackTrace);

  @override
  Widget build(BuildContext context, EventSnapshot<T> currentSummary) => builder(context, currentSummary);
}
