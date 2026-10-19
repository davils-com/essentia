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

import 'package:essentia_coroutines/essentia_coroutines.dart';

/// A counter that publishes its count through a `StateFlow`.
final class GuideCounterModel {
  /// The private mutable state.
  final MutableStateFlow<int> _counter = MutableStateFlow(0);

  /// The count, read-only.
  StateFlow<int> get counter => _counter.asStateFlow();

  /// Counts one up.
  void inc() => _counter.update((count) => count + 1);
}
