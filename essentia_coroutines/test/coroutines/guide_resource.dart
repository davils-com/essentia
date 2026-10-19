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

import 'guide_counter.dart';

/// A resource of the cancellation and timeout examples that counts how many are
/// open.
final class GuideResource {
  /// Opens the resource.
  GuideResource(this.counter) {
    counter.open++;
  }

  /// The counter of open resources.
  final GuideCounter counter;

  /// Closes the resource.
  void close() => counter.open--;
}
