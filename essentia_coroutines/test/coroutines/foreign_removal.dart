/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

/// A [Disposable] that runs an action.
final class ForeignRemoval implements Disposable {
  /// Creates the handle running [_action].
  const ForeignRemoval(this._action);

  /// What dispose runs.
  final void Function() _action;

  /// See [Disposable.dispose].
  @override
  void dispose() => _action();
}
