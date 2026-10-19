/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/text/linear_reg_exp_failure.dart';

/// A pattern `LinearRegExp` refuses: why, and where in the pattern.
///
/// The message names the reason and the offset, never the pattern, which
/// may come from a document nobody trusts.
final class LinearRegExpException implements Exception {
  /// Refuses a pattern for [failure] at [offset], explained by [detail].
  const LinearRegExpException(this.failure, this.offset, this.detail);

  /// Why the pattern is refused.
  final LinearRegExpFailure failure;

  /// The index of the code unit of the pattern the problem was found at.
  final int offset;

  /// What was wrong there, such as `an unterminated group`.
  final String detail;

  /// The reason, the detail and the offset.
  @override
  String toString() =>
      'LinearRegExpException: ${failure.name} at offset $offset: $detail';
}
