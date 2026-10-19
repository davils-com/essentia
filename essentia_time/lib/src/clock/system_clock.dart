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

import 'package:essentia_time/src/clock/clock.dart';
import 'package:essentia_time/src/instant.dart';
import 'package:meta/meta.dart';

/// The clock behind `Clock.system`, which reads `DateTime.now()`.
final class SystemClock implements Clock {
  /// Creates the system clock.
  ///
  /// There is one, `Clock.system`; nothing else creates another.
  @internal
  const SystemClock();

  /// Reads the time of the system.
  ///
  /// Returns the moment it is now.
  @override
  Instant now() => Instant.fromDateTime(DateTime.now());

  /// Names the clock.
  @override
  String toString() => 'Clock(system)';
}
