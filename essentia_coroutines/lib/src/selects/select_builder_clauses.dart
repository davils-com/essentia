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

import 'package:essentia_coroutines/src/channels/channel_result.dart';
import 'package:essentia_coroutines/src/channels/receive_channel.dart';
import 'package:essentia_coroutines/src/channels/send_channel.dart';
import 'package:essentia_coroutines/src/deferred/deferred.dart';
import 'package:essentia_coroutines/src/job/job.dart';
import 'package:essentia_coroutines/src/selects/deferred_select_clauses.dart';
import 'package:essentia_coroutines/src/selects/future_clause.dart';
import 'package:essentia_coroutines/src/selects/job_select_clauses.dart';
import 'package:essentia_coroutines/src/selects/select_builder.dart';

/// The clauses of `select`, spelled as calls on the builder.
///
/// A clause is written `it.onReceive(channel, (value) => ...)`, the same as
/// `it.invoke(channel.onReceive, (value) => ...)`.
extension SelectBuilderClauses<R> on SelectBuilder<R> {
  /// Selects the value of [deferred] once it is complete; a failed deferred
  /// makes the select throw its failure.
  void onAwait<T>(Deferred<T> deferred, FutureOr<R> Function(T value) block) =>
      invoke(deferred.onAwait, block);

  /// Selects once [job] is complete.
  void onJoin(Job job, FutureOr<R> Function() block) =>
      invoke(job.onJoin, (value) => block());

  /// Selects an element received from [channel]; a channel closed for receive
  /// makes the select throw what `receive` would.
  void onReceive<E>(
    ReceiveChannel<E> channel,
    FutureOr<R> Function(E value) block,
  ) => invoke(channel.onReceive, block);

  /// Selects an element received from [channel], or its closure.
  void onReceiveCatching<E>(
    ReceiveChannel<E> channel,
    FutureOr<R> Function(ChannelResult<E> result) block,
  ) => invoke(channel.onReceiveCatching, block);

  /// Selects once [channel] took [element]; a closed channel makes the select
  /// throw what `send` would.
  void onSend<E>(
    SendChannel<E> channel,
    E element,
    FutureOr<R> Function(SendChannel<E> channel) block,
  ) => invoke(channel.onSend(element), block);

  /// Selects the value of a plain [future], an addition of Essentia: Dart
  /// code waits for futures that are no `Deferred`.
  ///
  /// A failed future makes the select throw its failure. The clause is
  /// never ready during registration, not even for a completed future,
  /// because a future reports its value in a later microtask; and a select
  /// that ends otherwise only stops listening to the future.
  void onFuture<T>(Future<T> future, FutureOr<R> Function(T value) block) =>
      invoke(FutureClause<T>(future), block);
}
