/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/flow/shared_flow.dart';
import 'package:meta/meta.dart';

/// A read-only view of a shared flow, Kotlin's `ReadonlySharedFlow`.
@internal
final class ReadonlySharedFlow<T> extends Stream<T> implements SharedFlow<T> {
  /// Creates the view of [_flow].
  ReadonlySharedFlow(this._flow);

  /// The flow behind the view.
  final SharedFlow<T> _flow;

  /// A shared flow is a broadcast stream.
  @override
  bool get isBroadcast => true;

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
