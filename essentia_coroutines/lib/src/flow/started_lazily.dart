/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/flow/sharing_command.dart';
import 'package:essentia_coroutines/src/flow/sharing_started.dart';
import 'package:essentia_coroutines/src/flow/state_flow.dart';
import 'package:meta/meta.dart';

/// The strategy behind `SharingStarted.lazily`, Kotlin's `StartedLazily`.
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
