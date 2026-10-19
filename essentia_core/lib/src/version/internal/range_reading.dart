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

import 'package:essentia_core/src/version/version_interval.dart';
import 'package:meta/meta.dart';

/// What came of reading a text, or a part of one, as a version range: the
/// intervals it holds, or why it is not a range.
@internal
@immutable
sealed class RangeReading {
  /// Creates the reading.
  const RangeReading();
}

/// A text that was a range.
@internal
@immutable
final class RangeRead extends RangeReading {
  /// Creates the reading of [intervals].
  const RangeRead(this.intervals);

  /// The intervals read; disjoint and ascending once the whole range was
  /// read.
  final List<VersionInterval> intervals;
}

/// A text that was not a range, or matched no version.
@internal
@immutable
final class RangeRefused extends RangeReading {
  /// Creates the refusal saying [reason].
  const RangeRefused(this.reason);

  /// What was wrong, phrased to follow `it`.
  final String reason;
}
