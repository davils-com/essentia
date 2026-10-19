/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// A set of code points one step of a pattern consumes: ranges of code
/// points and Unicode properties, or everything but them.
///
/// A Unicode property is tested by a `RegExp` of the property alone on the
/// one code point at hand, which cannot backtrack.
@internal
@immutable
final class CodePointClass {
  /// The class of the inclusive [ranges], given as pairs of the first and
  /// the last code point, and of the code points [properties] match, or of
  /// every other code point when [negated].
  CodePointClass(
    List<int> ranges, {
    List<RegExp> properties = const <RegExp>[],
    this.negated = false,
  }) : _ranges = _normalized(ranges),
       _properties = List<RegExp>.unmodifiable(properties);

  /// The class of the one code point [codePoint].
  CodePointClass.single(int codePoint) : this(<int>[codePoint, codePoint]);

  /// The class of every code point but a line terminator: what `.` stands
  /// for.
  static final anyButLineTerminator = CodePointClass(
    lineTerminators,
    negated: true,
  );

  /// The highest code point.
  static const maxCodePoint = 0x10FFFF;

  /// The digits `0` to `9`: `\d`.
  static const digits = <int>[0x30, 0x39];

  /// The ASCII letters, the digits and `_`: `\w`.
  static const wordCharacters = <int>[
    0x30,
    0x39,
    0x41,
    0x5A,
    0x5F,
    0x5F,
    0x61,
    0x7A,
  ];

  /// What ECMAScript counts as white space or a line terminator: `\s`.
  static const whiteSpace = <int>[
    0x09,
    0x0D,
    0x20,
    0x20,
    0xA0,
    0xA0,
    0x1680,
    0x1680,
    0x2000,
    0x200A,
    0x2028,
    0x2029,
    0x202F,
    0x202F,
    0x205F,
    0x205F,
    0x3000,
    0x3000,
    0xFEFF,
    0xFEFF,
  ];

  /// The line terminators of ECMAScript: `\n`, `\r`, U+2028 and U+2029.
  static const lineTerminators = <int>[0x0A, 0x0A, 0x0D, 0x0D, 0x2028, 0x2029];

  /// The ranges, sorted and merged, as pairs of the first and the last code
  /// point.
  final List<int> _ranges;

  /// The Unicode properties, each a `RegExp` of one property alone.
  final List<RegExp> _properties;

  /// Whether the class holds every code point but its ranges and
  /// properties.
  final bool negated;

  /// The ranges, sorted and merged, as pairs of the first and the last code
  /// point.
  List<int> get ranges => _ranges;

  /// The Unicode properties, each a `RegExp` of one property alone.
  List<RegExp> get properties => _properties;

  /// Whether the class holds [codePoint].
  bool matches(int codePoint) {
    if (_inRanges(codePoint)) {
      return !negated;
    }
    if (_properties.isNotEmpty) {
      final character = String.fromCharCode(codePoint);
      for (final RegExp property in _properties) {
        if (property.hasMatch(character)) {
          return !negated;
        }
      }
    }
    return negated;
  }

  /// Whether one of the ranges holds [codePoint], found by bisection.
  bool _inRanges(int codePoint) {
    var low = 0;
    int high = _ranges.length ~/ 2 - 1;
    while (low <= high) {
      final int middle = (low + high) ~/ 2;
      if (codePoint < _ranges[middle * 2]) {
        high = middle - 1;
        continue;
      }
      if (codePoint > _ranges[middle * 2 + 1]) {
        low = middle + 1;
        continue;
      }
      return true;
    }
    return false;
  }

  /// Every code point [ranges] leaves out, as ranges.
  ///
  /// Returns them.
  static List<int> complement(List<int> ranges) {
    final List<int> sorted = _normalized(ranges);
    final complement = <int>[];
    var next = 0;
    for (var index = 0; index < sorted.length; index += 2) {
      if (sorted[index] > next) {
        complement
          ..add(next)
          ..add(sorted[index] - 1);
      }
      next = sorted[index + 1] + 1;
    }
    if (next <= maxCodePoint) {
      complement
        ..add(next)
        ..add(maxCodePoint);
    }
    return complement;
  }

  /// [ranges] sorted by their first code point, overlapping and adjacent
  /// ones merged.
  ///
  /// Returns them.
  static List<int> _normalized(List<int> ranges) {
    final pairs = <(int, int)>[
      for (var index = 0; index + 1 < ranges.length; index += 2)
        (ranges[index], ranges[index + 1]),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    final merged = <int>[];
    for (final (int first, int last) in pairs) {
      if (merged.isNotEmpty && first <= merged.last + 1) {
        if (last > merged.last) {
          merged.last = last;
        }
        continue;
      }
      merged
        ..add(first)
        ..add(last);
    }
    return List<int>.unmodifiable(merged);
  }
}
