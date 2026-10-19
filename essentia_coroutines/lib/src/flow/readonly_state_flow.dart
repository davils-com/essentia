/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_coroutines/src/flow/shared_flow.dart';
import 'package:essentia_coroutines/src/flow/state_flow.dart';
import 'package:meta/meta.dart';

/// A read-only view of a state flow.
@internal
final class ReadonlyStateFlow<T> extends Stream<T> implements StateFlow<T> {
  /// Creates the view of [_flow].
  ReadonlyStateFlow(this._flow);

  /// The flow behind the view.
  final StateFlow<T> _flow;

  /// A state flow is a broadcast stream.
  @override
  bool get isBroadcast => true;

  /// See [Stream.value].
  @override
  T get value => _flow.value;

  /// See [SharedFlow.replayCache].
  @override
  List<T> get replayCache => _flow.replayCache;

  /// Subscribes a listener to the flow behind the view.
  ///
  /// Returns the subscription.
  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _flow.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  /// Renders the flow behind the view.
  @override
  String toString() => _flow.toString();
}
