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

import 'package:essentia_coroutines/src/testing/test_scope.dart';
import 'package:essentia_time/essentia_time.dart';

/// The operations on a `TestScope` that move the virtual time of the test.
extension TestScopeTime on TestScope {
  /// The virtual time passed since the test started.
  Duration get currentTime => testScheduler.currentTime;

  /// The time source of the virtual time.
  TimeSource get testTimeSource => testScheduler;

  /// Moves virtual time on by [duration], running what falls due.
  ///
  /// Throws an [ArgumentError] if [duration] is negative.
  void advanceTimeBy(Duration duration) =>
      testScheduler.advanceTimeBySync(duration);

  /// Runs what is due at the current virtual time.
  void runCurrent() => testScheduler.runCurrentSync();

  /// Runs everything that is not background work, moving virtual time on as
  /// needed.
  void advanceUntilIdle() => testScheduler.advanceUntilIdleSync();
}
