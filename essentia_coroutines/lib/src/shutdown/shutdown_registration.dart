/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/src/shutdown/shutdown_hook.dart';
import 'package:meta/meta.dart';

/// A hook added to `ShutdownHooks`, and the handle that removes it.
@internal
final class ShutdownRegistration implements Disposable {
  /// Creates the registration of [hook], removed through [_remove].
  ShutdownRegistration(this.hook, this._remove);

  /// The hook.
  final ShutdownHook hook;

  /// Removes this registration from its hooks.
  final void Function(ShutdownRegistration registration) _remove;

  /// Whether [dispose] ran.
  var _disposed = false;

  /// Removes the hook; a second call does nothing.
  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _remove(this);
  }
}
