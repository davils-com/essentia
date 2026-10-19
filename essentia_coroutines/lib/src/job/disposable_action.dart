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
