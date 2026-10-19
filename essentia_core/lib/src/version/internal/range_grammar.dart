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

import 'package:essentia_core/src/text/string_blankness.dart';
import 'package:essentia_core/src/version/internal/comparator_grammar.dart';
import 'package:essentia_core/src/version/internal/interval_algebra.dart';
import 'package:essentia_core/src/version/internal/interval_grammar.dart';
import 'package:essentia_core/src/version/internal/range_reading.dart';
import 'package:essentia_core/src/version/internal/version_grammar.dart';
import 'package:essentia_core/src/version/version_interval.dart';
import 'package:meta/meta.dart';

/// The longest text read as a range, so that an absurd one is refused
/// before it is split.
const _maxRangeLength = 1024;

/// Why a text longer than [_maxRangeLength] is not a range.
const _rangeTooLongReason = 'is longer than $_maxRangeLength characters';

/// Why an empty alternative is refused.
const _emptyAlternativeReason = 'has an empty alternative beside ||';

/// Why an alternative that matches no version is refused.
@internal
const matchesNothingReason = 'has an alternative that matches no version';

/// What separates the alternatives of a range.
const _alternativeSeparator = '||';

/// What an alternative in interval notation starts with.
const _intervalOpenings = '[(';

/// Reads [text] as a version range, in either notation, with alternatives
/// joined by `||`.
///
/// Returns the disjoint, ascending intervals read, or why [text] is not a
/// range.
@internal
RangeReading readRange(String text) {
  if (text.isBlank) {
    return const RangeRefused(emptyReason);
  }
  if (text.length > _maxRangeLength) {
    return const RangeRefused(_rangeTooLongReason);
  }

  final intervals = <VersionInterval>[];
  for (final String alternative in text.split(_alternativeSeparator)) {
    final RangeReading reading = _readAlternative(alternative.trim());
    switch (reading) {
      case RangeRead():
        intervals.addAll(reading.intervals);
      case RangeRefused():
        return reading;
    }
  }
  return RangeRead(normalized(intervals));
}

/// Reads the alternative [text], in the notation it starts with.
///
/// Returns the intervals read, or why [text] is not a range.
RangeReading _readAlternative(String text) {
  if (text.isEmpty) {
    return const RangeRefused(_emptyAlternativeReason);
  }
  if (_intervalOpenings.contains(text[0])) {
    return readIntervals(text);
  }
  return readComparatorSet(text);
}
