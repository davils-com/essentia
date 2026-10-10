/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// An iCalendar file that a strict read refuses, with every [problems] it
/// found, not only the first.
final class IcsParseException implements Exception {
  /// The refusal for [problems].
  IcsParseException(List<String> problems)
    : problems = List<String>.unmodifiable(problems);

  /// What is wrong with the file, each as `where: what`.
  final List<String> problems;

  /// Describes the refusal and its problems.
  @override
  String toString() =>
      'IcsParseException (${problems.length} problems):\n  '
      '${problems.join('\n  ')}';
}
