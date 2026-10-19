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
