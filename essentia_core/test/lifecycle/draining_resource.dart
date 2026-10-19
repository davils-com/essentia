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

import 'dart:async';

import 'package:essentia_core/essentia_core.dart';

/// A [DisposableAsync] whose teardown waits until the test lets it drain.
final class DrainingResource implements DisposableAsync {
  /// Completed by the test once the teardown may finish.
  final drained = Completer<void>();

  /// How often the teardown actually started.
  var _disposals = 0;

  /// The teardown in progress or settled, or `null` before the first call.
  Future<void>? _teardown;

  /// How often the teardown actually started.
  int get disposals => _disposals;

  /// Starts the teardown, or joins the one already started.
  @override
  Future<void> dispose() => _teardown ??= _drain();

  /// Counts the teardown and waits until the test lets it drain.
  Future<void> _drain() async {
    _disposals++;
    await drained.future;
  }
}
