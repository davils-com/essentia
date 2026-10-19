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

import 'package:essentia_core/src/collection/map_with_default.dart';
import 'package:meta/meta.dart';

/// Gives a map a default for missing keys.
extension MapDefaulting<K, V> on Map<K, V> {
  /// A read only view of this map whose `getValue` derives the value of
  /// a missing key from [defaultOf].
  ///
  /// Returns the view.
  @useResult
  MapWithDefault<K, V> withDefault(V Function(K key) defaultOf) =>
      MapWithDefault<K, V>(this, defaultOf);
}
