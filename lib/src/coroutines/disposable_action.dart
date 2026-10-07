/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/lifecycle/disposable.dart';
import 'package:meta/meta.dart';

/// A [Disposable] that runs an action on its first `dispose`.
@internal
final class DisposableAction implements Disposable {
  /// Creates the handle running [_action] once.
  DisposableAction(this._action);

  /// A handle that does nothing.
  static final Disposable none = DisposableAction(_nothing);

  /// What `dispose` runs, `null` once it ran.
  void Function()? _action;

  /// Runs the action unless it ran already.
  @override
  void dispose() {
    final void Function()? action = _action;
    _action = null;
    action?.call();
  }

  /// Does nothing.
  static void _nothing() {}
}
