/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/version/internal/partial.dart';
import 'package:meta/meta.dart';

/// What came of reading the operand of a comparator: the partial version,
/// or why it is not one.
@internal
@immutable
sealed class PartialReading {
  /// Creates the reading.
  const PartialReading();
}

/// An operand that was a partial version.
@internal
@immutable
final class PartialRead extends PartialReading {
  /// Creates the reading of [partial].
  const PartialRead(this.partial);

  /// The partial version read.
  final Partial partial;
}

/// An operand that was not a partial version.
@internal
@immutable
final class PartialRefused extends PartialReading {
  /// Creates the refusal saying [reason].
  const PartialRefused(this.reason);

  /// What was wrong, phrased to follow `it`.
  final String reason;
}
