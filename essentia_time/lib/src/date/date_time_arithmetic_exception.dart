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

/// A calculation on dates and times whose result does not exist: a moment
/// beyond the range of an `Instant`, or a local time a shift of the clocks
/// skips when `ZoneResolution.strict` was asked for.
final class DateTimeArithmeticException implements Exception {
  /// Creates the exception that tells what went wrong in [message].
  const DateTimeArithmeticException(this.message);

  /// What went wrong.
  final String message;

  /// Describes the exception.
  @override
  String toString() => 'DateTimeArithmeticException: $message';
}
