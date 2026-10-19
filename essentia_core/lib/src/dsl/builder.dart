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

/// Something that assembles a value of type [T] from what a configuration
/// block set on it.
///
/// A builder is mutable and short-lived: it exists for the duration of one
/// block, and the value it produces is immutable. Most builders want
/// `ValidatingBuilder` instead, which adds validation to this contract.
abstract interface class Builder<T> {
  /// Produces the value.
  ///
  /// Returns the built value.
  T build();
}
