/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:math';

import 'package:essentia/src/validation/column.dart';
import 'package:essentia/src/validation/severity.dart';
import 'package:essentia/src/validation/violation.dart';
import 'package:meta/meta.dart';

/// The widest the path column of a report grows before longer paths push
/// their message to the right.
const _pathColumnLimit = 28;

/// The gap between the path column and the message.
const _pathGap = 2;

/// The indentation of every violation line.
const _indent = '  ';

/// Renders a report about [subject] listing [violations], errors first, then
/// warnings, followed by [footer] when there is one.
///
/// Returns the rendered report without a trailing newline.
@internal
String renderReport(
  String subject,
  List<Violation> violations,
  String? footer,
) {
  final blocks = <String>[];
  final List<Violation> errors = _withSeverity(violations, Severity.error);
  final List<Violation> warnings = _withSeverity(violations, Severity.warning);
  if (errors.isNotEmpty) {
    blocks
      ..add(_errorHeadline(subject, errors.length))
      ..add(_renderLines(errors));
  }
  if (warnings.isNotEmpty) {
    blocks
      ..add(_warningHeadline(warnings.length))
      ..add(_renderLines(warnings));
  }
  if (footer != null) {
    blocks.add(footer);
  }
  return blocks.join('\n\n');
}

/// Selects the violations of [violations] that carry [severity].
///
/// Returns them in the order they were reported.
List<Violation> _withSeverity(List<Violation> violations, Severity severity) =>
    violations.where((violation) => violation.severity == severity).toList();

/// The headline above the errors of a report about [subject].
///
/// Returns `Invalid <subject> (<count> problems):`.
String _errorHeadline(String subject, int count) {
  if (count == 1) {
    return 'Invalid $subject (1 problem):';
  }
  return 'Invalid $subject ($count problems):';
}

/// The headline above [count] warnings.
///
/// Returns `<count> warnings:`.
String _warningHeadline(int count) {
  if (count == 1) {
    return '1 warning:';
  }
  return '$count warnings:';
}

/// Renders [violations] as aligned lines of path and message.
///
/// Returns the lines joined by newlines.
String _renderLines(List<Violation> violations) {
  final int width = _columnWidth(violations);
  return violations
      .map((violation) {
        final String path = column(violation.path.toString(), width);
        return '$_indent$path${violation.message}';
      })
      .join('\n');
}

/// The width of the path column for [violations].
///
/// Returns the longest path, capped at the limit, plus the gap.
int _columnWidth(List<Violation> violations) {
  final int longest = violations
      .map((violation) => violation.path.toString().length)
      .reduce(max);
  return min(longest, _pathColumnLimit) + _pathGap;
}
