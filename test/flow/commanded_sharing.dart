/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/essentia.dart';

/// A sharing strategy that issues the commands a test adds to [commands].
final class CommandedSharing implements SharingStarted {
  /// Creates the strategy issuing [commands].
  CommandedSharing(this.commands);

  /// The commands to issue.
  final StreamController<SharingCommand> commands;

  /// Issues the commands of the test.
  ///
  /// Returns their stream.
  @override
  Stream<SharingCommand> command(StateFlow<int> subscriptionCount) =>
      commands.stream;
}
