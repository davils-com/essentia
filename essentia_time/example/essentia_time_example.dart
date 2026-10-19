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

import 'dart:io';

import 'package:essentia_time/essentia_time.dart';

/// Moves a meeting in Berlin across the start of daylight saving time.
void main() {
  final TimeZone berlin = TimeZone.of('Europe/Berlin');
  final Instant start = LocalDateTime.of(2026, 3, 28, 9, 0).toInstant(berlin);
  final Instant next = start.plus(1, DateTimeUnit.day, timeZone: berlin);

  stdout
    ..writeln(start.format(DateTimeFormats.isoInstantUtc))
    ..writeln(next.format(DateTimeFormats.isoInstantUtc));
}
