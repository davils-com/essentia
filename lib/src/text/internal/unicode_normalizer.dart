/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// The Unicode normalization forms NFC and NFD of UAX #15: canonical
/// decomposition, canonical ordering and canonical composition, Hangul
/// syllables included, on code points.
@internal
library;

import 'package:essentia/src/text/internal/quick_check_result.dart';
import 'package:essentia/src/text/internal/unicode_character_data.dart';
import 'package:meta/meta.dart';

/// The first code unit that can make text other than NFC: every code point
/// below it is a starter that NFC keeps.
const _firstNfcRelevant = 0x300;

/// The first code unit that can make text other than NFD: every code point
/// below it is a starter without a decomposition.
const _firstNfdRelevant = 0xC0;

/// The first precomposed Hangul syllable.
const _syllableBase = 0xAC00;

/// The first leading consonant jamo.
const _leadingBase = 0x1100;

/// The first vowel jamo.
const _vowelBase = 0x1161;

/// The code point before the first trailing consonant jamo.
const _trailingBase = 0x11A7;

/// The number of leading consonant jamo.
const _leadingCount = 19;

/// The number of vowel jamo.
const _vowelCount = 21;

/// The number of trailing consonant jamo, plus one for none.
const _trailingCount = 28;

/// The number of syllables that share a leading consonant.
const int _syllablesPerLeading = _vowelCount * _trailingCount;

/// The number of precomposed Hangul syllables.
const int _syllableCount = _leadingCount * _syllablesPerLeading;

/// Brings [text] into the Normalization Form C.
///
/// Returns [text] itself when it already is.
String normalizeNfc(String text) {
  if (_allCodeUnitsBelow(text, _firstNfcRelevant) ||
      _nfcQuickCheck(text) == QuickCheckResult.yes) {
    return text;
  }
  final String normalized = _composed(text);
  return normalized == text ? text : normalized;
}

/// Brings [text] into the Normalization Form D.
///
/// Returns [text] itself when it already is.
String normalizeNfd(String text) {
  if (_allCodeUnitsBelow(text, _firstNfdRelevant) || _isQuicklyNfd(text)) {
    return text;
  }
  final (List<int> codePoints, _) = _decomposed(text);
  return String.fromCharCodes(codePoints);
}

/// Whether [text] is in the Normalization Form C.
bool isNormalizedNfc(String text) {
  if (_allCodeUnitsBelow(text, _firstNfcRelevant)) {
    return true;
  }
  return switch (_nfcQuickCheck(text)) {
    QuickCheckResult.yes => true,
    QuickCheckResult.no => false,
    QuickCheckResult.maybe => _composed(text) == text,
  };
}

/// Whether every code unit of [text] is below [limit].
bool _allCodeUnitsBelow(String text, int limit) {
  for (var index = 0; index < text.length; index++) {
    if (text.codeUnitAt(index) >= limit) {
      return false;
    }
  }
  return true;
}

/// The NFC quick check of [text]: the quick check of each code point and
/// the canonical order of the combining marks.
///
/// Returns the least certain answer.
QuickCheckResult _nfcQuickCheck(String text) {
  QuickCheckResult result = QuickCheckResult.yes;
  var lastClass = 0;
  for (final int codePoint in text.runes) {
    final int combiningClass = combiningClassOf(codePoint);
    if (combiningClass != 0 && lastClass > combiningClass) {
      return QuickCheckResult.no;
    }
    lastClass = combiningClass;
    final QuickCheckResult check = nfcQuickCheckOf(codePoint);
    if (check == QuickCheckResult.no) {
      return QuickCheckResult.no;
    }
    if (check == QuickCheckResult.maybe) {
      result = QuickCheckResult.maybe;
    }
  }
  return result;
}

/// Whether [text] is certainly in NFD: no code point decomposes and the
/// combining marks are in canonical order.
bool _isQuicklyNfd(String text) {
  var lastClass = 0;
  for (final int codePoint in text.runes) {
    if (_isSyllable(codePoint) || canonicalDecompositionOf(codePoint) != null) {
      return false;
    }
    final int combiningClass = combiningClassOf(codePoint);
    if (combiningClass != 0 && lastClass > combiningClass) {
      return false;
    }
    lastClass = combiningClass;
  }
  return true;
}

/// The canonical decomposition of [text] in canonical order.
///
/// Returns its code points and the combining class of each.
(List<int>, List<int>) _decomposed(String text) {
  final codePoints = <int>[];
  final classes = <int>[];
  for (final int codePoint in text.runes) {
    _decomposeInto(codePoint, codePoints, classes);
  }
  return (codePoints, classes);
}

/// Appends the full canonical decomposition of [codePoint] to [codePoints]
/// and the combining classes to [classes], in canonical order.
void _decomposeInto(int codePoint, List<int> codePoints, List<int> classes) {
  if (_isSyllable(codePoint)) {
    final int index = codePoint - _syllableBase;
    final int trailing = index % _trailingCount;
    _appendOrdered(
      _leadingBase + index ~/ _syllablesPerLeading,
      codePoints,
      classes,
    );
    _appendOrdered(
      _vowelBase + (index % _syllablesPerLeading) ~/ _trailingCount,
      codePoints,
      classes,
    );
    if (trailing != 0) {
      _appendOrdered(_trailingBase + trailing, codePoints, classes);
    }
    return;
  }
  final (int, int)? mapping = canonicalDecompositionOf(codePoint);
  if (mapping == null) {
    _appendOrdered(codePoint, codePoints, classes);
    return;
  }
  final (int first, int second) = mapping;
  _decomposeInto(first, codePoints, classes);
  if (second != 0) {
    _decomposeInto(second, codePoints, classes);
  }
}

/// Appends [codePoint] to [codePoints] and its combining class to
/// [classes], moved before the combining marks of a higher class it
/// follows, so that every run of marks stays sorted stably by class.
void _appendOrdered(int codePoint, List<int> codePoints, List<int> classes) {
  final int combiningClass = combiningClassOf(codePoint);
  int position = codePoints.length;
  while (combiningClass != 0 &&
      position > 0 &&
      classes[position - 1] > combiningClass) {
    position--;
  }
  codePoints.insert(position, codePoint);
  classes.insert(position, combiningClass);
}

/// The canonical composition of the canonical decomposition of [text].
///
/// Returns the text in NFC.
String _composed(String text) {
  final (List<int> codePoints, List<int> classes) = _decomposed(text);
  final composed = <int>[];
  var starter = -1;
  var lastClass = 0;
  for (var index = 0; index < codePoints.length; index++) {
    final int codePoint = codePoints[index];
    final int combiningClass = classes[index];
    final bool unblocked =
        starter == composed.length - 1 ||
        (lastClass != 0 && lastClass < combiningClass);
    final int? composite = starter < 0 || !unblocked
        ? null
        : _compositeOf(composed[starter], codePoint);
    if (composite != null) {
      composed[starter] = composite;
      continue;
    }
    if (combiningClass == 0) {
      starter = composed.length;
    }
    lastClass = combiningClass;
    composed.add(codePoint);
  }
  return String.fromCharCodes(composed);
}

/// The primary composite of [first] and [second], Hangul syllables
/// included.
///
/// Returns `null` when the pair forms none.
int? _compositeOf(int first, int second) {
  final int leading = first - _leadingBase;
  final int vowel = second - _vowelBase;
  if (leading >= 0 &&
      leading < _leadingCount &&
      vowel >= 0 &&
      vowel < _vowelCount) {
    return _syllableBase + (leading * _vowelCount + vowel) * _trailingCount;
  }
  final int trailing = second - _trailingBase;
  if (_isSyllable(first) &&
      (first - _syllableBase) % _trailingCount == 0 &&
      trailing > 0 &&
      trailing < _trailingCount) {
    return first + trailing;
  }
  return primaryCompositeOf(first, second);
}

/// Whether [codePoint] is a precomposed Hangul syllable.
bool _isSyllable(int codePoint) =>
    codePoint >= _syllableBase && codePoint < _syllableBase + _syllableCount;
