/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';

import 'package:essentia_coroutines/src/flow/shared_flow.dart';
import 'package:meta/meta.dart';

/// A read-only view of a shared flow.
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
