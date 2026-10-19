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

/// Covers offsets from UTC: validation, ISO 8601 text and their zones.
void main() {
  test('builds offsets of parts that share a sign', () {
    expect(UtcOffset(hours: 2).totalSeconds, 7200);
    expect(UtcOffset(hours: -5, minutes: -30).totalSeconds, -19800);
    expect(UtcOffset(minutes: 45, seconds: 30).totalSeconds, 2730);
    expect(() => UtcOffset(hours: 1, minutes: -30), throwsArgumentError);
    expect(() => UtcOffset(minutes: 60), throwsArgumentError);
    expect(() => UtcOffset(hours: 19), throwsArgumentError);
    expect(() => UtcOffset.fromTotalSeconds(-64801), throwsArgumentError);
    expect(UtcOffset.fromTotalSeconds(64800).totalSeconds, 64800);
  });

  test('writes ISO 8601 text', () {
    expect(UtcOffset.zero.toString(), 'Z');
    expect(UtcOffset(hours: 2).toString(), '+02:00');
    expect(UtcOffset(hours: -3, minutes: -30).toString(), '-03:30');
    expect(UtcOffset(minutes: -25, seconds: -21).toString(), '-00:25:21');
  });

  test('reads every ISO 8601 form', () {
    expect(UtcOffset.parse('Z'), UtcOffset.zero);
    expect(UtcOffset.parse('z'), UtcOffset.zero);
    expect(UtcOffset.parse('+02'), UtcOffset(hours: 2));
    expect(UtcOffset.parse('+0530'), UtcOffset(hours: 5, minutes: 30));
    expect(UtcOffset.parse('-05:30'), UtcOffset(hours: -5, minutes: -30));
    expect(
      UtcOffset.parse('+01:02:03'),
      UtcOffset(hours: 1, minutes: 2, seconds: 3),
    );
    expect(
      UtcOffset.parse('+010203'),
      UtcOffset(hours: 1, minutes: 2, seconds: 3),
    );
    expect(() => UtcOffset.parse('+19:00'), throwsFormatException);
    expect(() => UtcOffset.parse('+01:60'), throwsFormatException);
    expect(() => UtcOffset.parse('01:00'), throwsFormatException);
  });

  test('orders, compares and becomes a zone', () {
    final east = UtcOffset(hours: 1);

    expect(east.compareTo(UtcOffset.zero), isPositive);
    expect(east, UtcOffset.parse('+01:00'));
    expect(east.hashCode, UtcOffset.parse('+01:00').hashCode);
    expect(east.asTimeZone().id, '+01:00');
    expect(east.asTimeZone().offset, east);
  });
}
