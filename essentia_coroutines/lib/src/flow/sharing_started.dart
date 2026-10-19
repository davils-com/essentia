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

import 'package:essentia_coroutines/src/flow/sharing_command.dart';
import 'package:essentia_coroutines/src/flow/started_eagerly.dart';
import 'package:essentia_coroutines/src/flow/started_lazily.dart';
import 'package:essentia_coroutines/src/flow/started_while_subscribed.dart';
import 'package:essentia_coroutines/src/flow/state_flow.dart';

/// When `shareIn` and `stateIn` listen to their upstream stream.
///
/// A strategy turns the count of listeners of the shared flow into
/// [SharingCommand]s; implement [command] for a strategy of your own.
abstract interface class SharingStarted {
  /// Starts at once and never stops.
  static const SharingStarted eagerly = StartedEagerly();

  /// Starts with the first listener and never stops.
  static const SharingStarted lazily = StartedLazily();

  /// Starts with the first listener and stops [stopTimeout] after the last
  /// one left.
  ///
  /// The replay values, or the value of a state flow, are kept for
  /// [replayExpiration] after stopping and then reset; without
  /// [replayExpiration] they are kept for good. The waits run on the
  /// scheduler of the sharing coroutine, so on virtual time in `runTest`.
  ///
  /// ```dart
  /// final StateFlow<User?> user = userUpdates.stateIn(
  ///   scope,
  ///   SharingStarted.whileSubscribed(stopTimeout: 5.seconds),
  ///   null,
  /// );
  /// ```
  ///
  /// Returns the strategy.
  ///
  /// Throws an [ArgumentError] if [stopTimeout] or [replayExpiration] is
  /// negative.
  static SharingStarted whileSubscribed({
    Duration stopTimeout = Duration.zero,
    Duration? replayExpiration,
  }) {
    if (stopTimeout.isNegative) {
      throw ArgumentError(
        'stopTimeout($stopTimeout) cannot be negative',
        'stopTimeout',
      );
    }
    if (replayExpiration != null && replayExpiration.isNegative) {
      throw ArgumentError(
        'replayExpiration($replayExpiration) cannot be negative',
        'replayExpiration',
      );
    }
    return StartedWhileSubscribed(
      stopTimeout: stopTimeout,
      replayExpiration: replayExpiration,
    );
  }

  /// The commands for the sharing coroutine, derived from
  /// [subscriptionCount], the count of listeners of the shared flow.
  ///
  /// Repeated commands are ignored, and commands before the first
  /// [SharingCommand.start] do nothing.
  ///
  /// Returns the stream of commands.
  Stream<SharingCommand> command(StateFlow<int> subscriptionCount);
}
