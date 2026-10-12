/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// How often a recurrence rule repeats, the `FREQ` of RFC 5545.
///
/// The frequencies are ordered from the finest to the coarsest, so
/// `index` compares them.
enum RecurrenceFrequency {
  /// Every second.
  secondly('SECONDLY'),

  /// Every minute.
  minutely('MINUTELY'),

  /// Every hour.
  hourly('HOURLY'),

  /// Every day.
  daily('DAILY'),

  /// Every week.
  weekly('WEEKLY'),

  /// Every month.
  monthly('MONTHLY'),

  /// Every year.
  yearly('YEARLY');

  /// Creates the frequency written as [token].
  const RecurrenceFrequency(this.token);

  /// The frequency of [token], such as `WEEKLY`, ignoring case, or `null`.
  static RecurrenceFrequency? ofToken(String token) {
    final String upper = token.toUpperCase();
    for (final RecurrenceFrequency frequency in values) {
      if (frequency.token == upper) {
        return frequency;
      }
    }
    return null;
  }

  /// How RFC 5545 writes the frequency.
  final String token;

  /// Whether the frequency repeats within a day.
  bool get isTimeBased => index < daily.index;
}
