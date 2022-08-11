import 'package:flutter/material.dart';

import 'value_stream.dart';

/// Signature for strategies that build widgets based on provided data
typedef DataWidgetBuilder<T> = Widget Function(BuildContext context, T value);

/// Widget that builds itself based on the latest value a [ValueStream].
class ValueStreamBuilder<T> extends StreamBuilderBase<T, T> {
  /// Widget that builds itself based on the latest value a [ValueStream].
  ValueStreamBuilder({
    super.key,
    required ValueStream<T> stream,
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
