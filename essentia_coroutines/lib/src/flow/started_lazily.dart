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
import 'package:essentia_coroutines/src/flow/sharing_started.dart';
import 'package:essentia_coroutines/src/flow/state_flow.dart';
import 'package:meta/meta.dart';

/// The strategy behind `SharingStarted.lazily`.
@internal
final class StartedLazily implements SharingStarted {
  /// Creates the strategy; there is one, `SharingStarted.lazily`.
  const StartedLazily();

  /// Starts with the first listener.
  ///
  /// Returns a stream that emits [SharingCommand.start] once
  /// [subscriptionCount] is positive.
  @override
  Stream<SharingCommand> command(StateFlow<int> subscriptionCount) =>
      subscriptionCount
          .where((count) => count > 0)
          .take(1)
          .map((_) => SharingCommand.start);

  /// Names the strategy.
  @override
  String toString() => 'SharingStarted.lazily';
}
