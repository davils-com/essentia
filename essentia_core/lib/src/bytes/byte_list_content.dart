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

/// Compares and hashes any list of bytes by its content.
extension ByteListContent on List<int> {
  /// Whether [other] holds the same elements in the same order.
  ///
  /// It stops at the first difference, so the time it takes tells how long
  /// the common prefix is: never compare secrets with it.
  ///
  /// Returns `true` when both lists are equal element by element, `false`
  /// when they differ or [other] is `null`.
  @useResult
  bool contentEquals(List<int>? other) {
    if (other == null || other.length != length) {
      return false;
    }
    for (var index = 0; index < length; index++) {
      if (this[index] != other[index]) {
        return false;
      }
    }
    return true;
  }

  /// A hash code of the elements, equal for lists that are
  /// [contentEquals].
  ///
  /// Returns the hash code.
  @useResult
  int contentHashCode() => Object.hashAll(this);
}
