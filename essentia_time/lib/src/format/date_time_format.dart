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

/// A format that writes a value of type [T] as text.
///
/// A format is immutable and can be shared freely. Essentia's own formats
/// are made with `localDateTimeFormat`, `localDateFormat`,
/// `localTimeFormat` and `localDateTimePattern`, and the common ones are
/// in `DateTimeFormats`; they write every field at its full width, unlike
/// the ISO 8601 `toString` of the values, which leaves out a zero second
/// and fraction.
///
/// ```dart
/// final DateTimeFormat<LocalDateTime> format = localDateTimePattern(
///   "dd.MM.yyyy 'at' HH:mm",
/// );
/// format.format(LocalDateTime.of(2026, 10, 10, 9, 5)); // 10.10.2026 at 09:05
/// ```
abstract interface class DateTimeFormat<T> {
  /// Writes [value] in this format.
  ///
  /// Returns the text.
  String format(T value);

  /// Writes [value] in this format to [out].
  void formatTo(StringSink out, T value);
}
