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

import 'package:meta/meta.dart';

/// Checks that an iterable of nullable elements holds no `null`.
extension IterableNullElements<T extends Object> on Iterable<T?> {
  /// Passes on the elements lazily, typed as present.
  ///
  /// The check happens as each element is reached rather than up front.
  ///
  /// Returns the elements as non-nullable ones.
  ///
  /// Throws an [ArgumentError] when a `null` element is reached.
  @useResult
  Iterable<T> requireNoNulls() => map(
    (element) => element ?? (throw ArgumentError('A null element was found.')),
  );
}
