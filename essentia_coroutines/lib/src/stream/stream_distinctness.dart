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

/// The distinctness operators for streams.
extension StreamDistinctness<T> on Stream<T> {
  /// Drops every element whose key, computed by [keyOf], equals the key of
  /// the element emitted before it.
  ///
  /// Only consecutive repetitions are dropped; a key that comes back later
  /// is emitted again.
  ///
  /// Returns a stream that is a broadcast stream exactly when this one is.
  Stream<T> distinctUntilChangedBy<K>(K Function(T element) keyOf) =>
      distinct((previous, next) => keyOf(previous) == keyOf(next));
}
