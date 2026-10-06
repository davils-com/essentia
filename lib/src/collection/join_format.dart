/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// How `joinToString` joins elements into one string: the parameters of
/// Kotlin's `joinToString`, `separator`, `prefix`, `postfix`, `limit` and
/// `truncated`, with Kotlin's defaults.
@immutable
final class JoinFormat {
  /// Creates a format; every argument defaults to Kotlin's default.
  ///
  /// Throws an [AssertionError] if [limit] is negative, when assertions
  /// are enabled.
  const JoinFormat({
    this.separator = ', ',
    this.prefix = '',
    this.postfix = '',
    this.limit,
    this.truncated = '...',
  }) : assert(limit == null || limit >= 0, 'A limit must not be negative.');

  /// What is written between two elements.
  final String separator;

  /// What is written before the first element.
  final String prefix;

  /// What is written after the last element.
  final String postfix;

  /// How many elements are written at most, or `null` for all of them.
  final int? limit;

  /// What is written instead of the elements beyond [limit].
  final String truncated;

  /// Whether the element at position [count], counting from one, is still
  /// written.
  ///
  /// Returns `true` without a [limit] or while [count] is within it.
  bool admits(int count) => limit == null || count <= limit!;
}
