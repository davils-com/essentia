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

/// A sink that collects what it is given into [values].
final class CollectingSink<T> implements Sink<T> {
  /// Creates the sink that collects into [values].
  CollectingSink(this.values);

  /// What the sink was given.
  final List<T> values;

  /// Collects [data].
  @override
  void add(T data) {
    values.add(data);
  }

  /// Whether the sink was closed.
  var closed = false;

  /// Remembers that the sink was closed.
  @override
  void close() {
    closed = true;
  }
}
