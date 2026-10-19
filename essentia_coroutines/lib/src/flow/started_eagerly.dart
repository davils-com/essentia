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

/// The strategy behind `SharingStarted.eagerly`.
@internal
final class StartedEagerly implements SharingStarted {
  /// Creates the strategy; there is one, `SharingStarted.eagerly`.
  const StartedEagerly();

  /// Starts at once.
  ///
  /// Returns a stream of one [SharingCommand.start].
  @override
  Stream<SharingCommand> command(StateFlow<int> subscriptionCount) =>
      Stream<SharingCommand>.value(SharingCommand.start);

  /// Names the strategy.
  @override
  String toString() => 'SharingStarted.eagerly';
}
