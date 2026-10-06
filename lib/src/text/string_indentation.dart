/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/text/runes.dart';
import 'package:meta/meta.dart';

/// Every kind of line break Kotlin's `lines` splits at.
final _lineBreak = RegExp('\r\n|\n|\r');

/// The indent [StringIndentation.prependIndent] uses by default, the same
/// four spaces as Kotlin.
const _defaultIndent = '    ';

/// The margin prefix [StringIndentation.trimMargin] uses by default, the
/// same `|` as Kotlin.
const _defaultMarginPrefix = '|';

/// Kotlin's line and indentation operations: `lines`, `trimIndent`,
/// `replaceIndent`, `trimMargin` and `prependIndent`.
extension StringIndentation on String {
  /// Splits the text at every `\r\n`, `\n` and `\r`.
  ///
  /// Kotlin's `CharSequence.lines()`.
  ///
  /// Returns the lines as an unmodifiable list, an empty last line included.
  @useResult
  List<String> lines() => List<String>.unmodifiable(split(_lineBreak));

  /// Removes the indent all lines that are not blank share.
  ///
  /// A blank first and last line is dropped. Kotlin's `String.trimIndent()`.
  ///
  /// Returns the text without its common indent.
  @useResult
  String trimIndent() => replaceIndent('');

  /// Replaces the indent all lines that are not blank share by [newIndent].
  ///
  /// A blank first and last line is dropped. Kotlin's
  /// `String.replaceIndent`.
  ///
  /// Returns the reindented text.
  @useResult
  String replaceIndent(String newIndent) {
    final List<String> all = lines();
    final int commonIndent =
        all
            .where((line) => line.trim().isNotEmpty)
            .map(indentWidth)
            .fold<int?>(
              null,
              (smallest, width) =>
                  smallest == null || width < smallest ? width : smallest,
            ) ??
        0;
    return _reindent(
      all,
      newIndent,
      (line) => line.substring(commonIndent.clamp(0, line.length)),
    );
  }

  /// Removes the leading white space and [marginPrefix] from every line
  /// that starts with it after its white space.
  ///
  /// Lines without the prefix are kept as they are; a blank first and last
  /// line is dropped. Kotlin's `String.trimMargin`.
  ///
  /// Returns the text without its margins.
  ///
  /// Throws an [ArgumentError] if [marginPrefix] is blank.
  @useResult
  String trimMargin([String marginPrefix = _defaultMarginPrefix]) {
    if (marginPrefix.trim().isEmpty) {
      throw ArgumentError.value(marginPrefix, 'marginPrefix', 'is blank');
    }
    return _reindent(lines(), '', (line) {
      final int start = indentWidth(line);
      final bool marked =
          start < line.length && line.startsWith(marginPrefix, start);
      return marked ? line.substring(start + marginPrefix.length) : null;
    });
  }

  /// Puts [indent] in front of every line that is not blank.
  ///
  /// A blank line shorter than [indent] becomes [indent], a longer one is
  /// kept. Kotlin's `String.prependIndent`.
  ///
  /// Returns the indented text, its lines joined by `\n`.
  @useResult
  String prependIndent([String indent = _defaultIndent]) => lines()
      .map((line) {
        if (line.trim().isNotEmpty) {
          return '$indent$line';
        }
        return line.length < indent.length ? indent : line;
      })
      .join('\n');
}

/// Joins [lines] by `\n` after cutting each with [cutIndent] and putting
/// [newIndent] in front.
///
/// A blank first and last line is dropped; a line [cutIndent] answers with
/// `null` for is kept unchanged.
///
/// Returns the joined text.
String _reindent(
  List<String> lines,
  String newIndent,
  String? Function(String line) cutIndent,
) {
  final int lastIndex = lines.length - 1;
  final kept = <String>[];
  for (final (index, line) in lines.indexed) {
    final bool edge = index == 0 || index == lastIndex;
    if (edge && line.trim().isEmpty) {
      continue;
    }
    final String? cut = cutIndent(line);
    kept.add(cut == null ? line : '$newIndent$cut');
  }
  return kept.join('\n');
}
