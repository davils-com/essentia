/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/lang/causal.dart';

/// Thrown by a converter for a value it cannot convert.
///
/// The parameter loader catches this and turns it into one entry of the
/// report it assembles, so [message] should describe the expectation rather
/// than repeat the offending value: the report already prints the value and
/// the parameter it belongs to. `"is not a valid integer"` reads correctly
/// in that context; `"could not parse 'x'"` duplicates what the report
/// shows.
final class ConversionException implements Exception, Causal {
  /// Creates the exception describing what the converter expected, with the
  /// [cause] that made the value unusable when there was one.
  const ConversionException(this.message, [this.cause]);

  /// The description of what the converter expected.
  final String message;

  /// The failure that made the value unusable, or `null`.
  @override
  final Object? cause;

  /// Where [cause] was thrown, which is not recorded: `null`.
  @override
  StackTrace? get causeStackTrace => null;

  /// The [message].
  @override
  String toString() => message;
}
