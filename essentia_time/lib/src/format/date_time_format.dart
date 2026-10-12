/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// A format that writes a value of type [T] as text, Kotlin's
/// `kotlinx.datetime.format.DateTimeFormat`.
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
