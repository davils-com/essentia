/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/version/version_interval.dart';
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
