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

/// Something that happened because of an earlier failure, which it keeps.
///
/// Dart's errors and exceptions carry no cause of their own. The ones of
/// Essentia that wrap another failure implement this interface, so code
/// that reports a failure can walk the chain of causes without knowing
/// every type that has one:
///
/// ```dart
/// Object? failure = error;
/// while (failure is Causal) {
///   failure = failure.cause;
/// }
/// ```
abstract interface class Causal {
  /// The failure behind this one, or `null` when there was none.
  Object? get cause;

  /// Where [cause] was thrown, or `null` when that is not known.
  StackTrace? get causeStackTrace;
}
