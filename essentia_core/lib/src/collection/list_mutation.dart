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

/// Removes elements at either end of a mutable list.
extension ListMutation<T> on List<T> {
  /// Removes the first element of this list.
  ///
  /// Returns the removed element.
  ///
  /// Throws a [StateError] if the list is empty.
  T removeFirst() {
    if (isEmpty) {
      throw StateError('No element');
    }
    return removeAt(0);
  }

  /// Removes the first element of this list, if there is one.
  ///
  /// Returns the removed element, or `null` if the list is empty.
  T? removeFirstOrNull() => isEmpty ? null : removeAt(0);

  /// Removes the last element of this list, if there is one.
  ///
  /// Returns the removed element, or `null` if the list is empty.
  T? removeLastOrNull() => isEmpty ? null : removeLast();
}
