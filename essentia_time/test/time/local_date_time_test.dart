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

import 'package:essentia_time/essentia_time.dart';
import 'package:test/test.dart';

/// Covers dates with times of day: their parts, conversion to moments,
/// ordering and ISO 8601 text.
void main() {
  final moment = LocalDateTime.of(2026, 10, 9, 14, 30, 15, 5);

  test('exposes the parts of its date and time', () {
    expect(moment.year, 2026);
    expect(moment.month, Month.october);
    expect(moment.monthNumber, 10);
    expect(moment.day, 9);
    expect(moment.dayOfWeek, DayOfWeek.friday);
    expect(moment.dayOfYear, 282);
    expect(moment.hour, 14);
    expect(moment.minute, 30);
    expect(moment.second, 15);
    expect(moment.nanosecond, 5);
    expect(() => LocalDateTime.of(2026, 2, 30, 0, 0), throwsArgumentError);
  });

  test('turns into a moment at an offset or in a zone', () {
    final local = LocalDateTime.of(2026, 10, 9, 14, 30);

    expect(
      local.toInstantAt(UtcOffset(hours: 2)),
      Instant.parse('2026-10-09T12:30:00Z'),
    );
    expect(
      local.toInstant(TimeZone.of('Europe/Berlin')),
      Instant.parse('2026-10-09T12:30:00Z'),
    );
    expect(local.localEpochSeconds, 1791556200);
  });

  test('reads a DateTime as it reads', () {
    expect(
      LocalDateTime.fromDateTime(DateTime.utc(2026, 10, 9, 14, 30)),
      LocalDateTime.of(2026, 10, 9, 14, 30),
    );
  });

  test('orders and compares', () {
    final earlier = LocalDateTime.of(2026, 10, 9, 23, 59);
    final later = LocalDateTime.of(2026, 10, 10, 0, 0);

    expect(earlier.isBefore(later), isTrue);
    expect(later.isAfter(earlier), isTrue);
    expect(earlier.compareTo(LocalDateTime.of(2026, 10, 9, 23, 59)), 0);
    expect(LocalDateTime.of(2026, 10, 9, 1, 0).compareTo(earlier), isNegative);
    expect(earlier.hashCode, LocalDateTime.of(2026, 10, 9, 23, 59).hashCode);
    expect(earlier == later, isFalse);
  });

  test('writes and reads ISO 8601 text', () {
    expect(
      LocalDateTime.of(2026, 10, 9, 14, 30).toString(),
      '2026-10-09T14:30',
    );
    expect(moment.toString(), '2026-10-09T14:30:15.000000005');
    expect(
      LocalDateTime.parse('2026-10-09T14:30:15'),
      LocalDateTime.of(2026, 10, 9, 14, 30, 15),
    );
    expect(
      LocalDateTime.parse('2026-10-09t14:30'),
      LocalDateTime.of(2026, 10, 9, 14, 30),
    );
    expect(
      () => LocalDateTime.parse('2026-10-09 14:30'),
      throwsFormatException,
    );
    expect(
      () => LocalDateTime.parse('2026-10-09T25:30'),
      throwsFormatException,
    );
  });
}
