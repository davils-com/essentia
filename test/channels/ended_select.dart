/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/lifecycle/disposable.dart';
import 'package:essentia/src/selects/select_instance.dart';

/// A select that is over already but keeps what it is handed, so a channel
/// is left holding a waiter that can no longer take part.
final class EndedSelect implements SelectInstance {
  /// The handles the channel handed over, never disposed.
  final handles = <Disposable>[];

  /// See [SelectInstance.owner].
  @override
  Object get owner => this;

  /// Refuses every clause.
  ///
  /// Returns `false`.
  @override
  bool trySelect(Object? result, {void Function()? onCancellation}) => false;

  /// See [SelectInstance.disposeOnCompletion].
  @override
  void disposeOnCompletion(Disposable handle) => handles.add(handle);
}
