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

import 'package:essentia_coroutines/src/continuation/suspension.dart';
import 'package:essentia_coroutines/src/flow/sharing_command.dart';
import 'package:essentia_coroutines/src/flow/sharing_started.dart';
import 'package:essentia_coroutines/src/flow/state_flow.dart';
import 'package:essentia_coroutines/src/stream/stream_mapping.dart';
import 'package:meta/meta.dart';

/// The strategy behind `SharingStarted.whileSubscribed`.
@immutable
@internal
final class StartedWhileSubscribed implements SharingStarted {
  /// Creates the strategy stopping [stopTimeout] after the last listener
  /// left and resetting [replayExpiration] after that, never without it.
  const StartedWhileSubscribed({
    required this.stopTimeout,
    required this.replayExpiration,
  });

  /// How long the upstream stream stays listened to after the last
  /// listener left.
  final Duration stopTimeout;

  /// How long the replay values are kept after stopping, `null` for good.
  final Duration? replayExpiration;

  /// Starts with a listener, stops [stopTimeout] after the last one left
  /// and resets [replayExpiration] after that.
  ///
  /// Returns the stream of commands.
  @override
  Stream<SharingCommand> command(StateFlow<int> subscriptionCount) =>
      subscriptionCount
          .transformLatest<SharingCommand>((it, count) async {
            if (count > 0) {
              await it.emit(SharingCommand.start);
              return;
            }
            await delay(stopTimeout);
            final Duration? expiration = replayExpiration;
            if (expiration == null) {
              await it.emit(SharingCommand.stop);
              return;
            }
            if (expiration > Duration.zero) {
              await it.emit(SharingCommand.stop);
              await delay(expiration);
            }
            await it.emit(SharingCommand.stopAndResetReplayCache);
          })
          .skipWhile((command) => command != SharingCommand.start)
          .distinct();

  /// Whether [other] is a strategy with the same timing.
  @override
  bool operator ==(Object other) =>
      other is StartedWhileSubscribed &&
      other.stopTimeout == stopTimeout &&
      other.replayExpiration == replayExpiration;

  /// The hash of the timing.
  @override
  int get hashCode => Object.hash(stopTimeout, replayExpiration);

  /// Names the strategy with its timing.
  @override
  String toString() {
    final Duration? expiration = replayExpiration;
    if (expiration == null) {
      return 'SharingStarted.whileSubscribed(stopTimeout: $stopTimeout)';
    }
    return 'SharingStarted.whileSubscribed(stopTimeout: $stopTimeout, '
        'replayExpiration: $expiration)';
  }
}
