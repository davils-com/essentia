/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// The lookups of the Unicode character data the normalization forms need,
/// on the tables of `unicode_normalization_data.dart`, each decoded once on
/// first use and searched by bisection.
@internal
library;

import 'package:essentia_core/src/text/internal/quick_check_result.dart';
import 'package:essentia_core/src/text/internal/unicode_normalization_data.dart';
import 'package:meta/meta.dart';

/// The first code point that has a canonical combining class other than 0
/// or an NFC quick check other than Yes.
const _firstMark = 0x300;

/// The first code point that has a canonical decomposition.
const _firstDecomposable = 0xC0;

/// The factor that puts the first code point of a composition pair above
/// the second in one key, exact on every platform.
const _pairKeyFactor = 0x110000;

/// The width of a record of the decomposition and composition tables.
const _pairRecordWidth = 18;

/// The width of a record of [combiningClassTable].
const _classRecordWidth = 14;

/// The width of a record of [nfcQuickCheckTable].
const _quickCheckRecordWidth = 13;

/// The width of a code point field.
const _codePointWidth = 6;

/// The code points that have a canonical decomposition, sorted.
final List<int> _decomposed = _column(
  canonicalDecompositionTable,
  canonicalDecompositionCount,
  _pairRecordWidth,
  0,
  _codePointWidth,
);

/// The first code point of the mapping of each of [_decomposed].
final List<int> _decompositionFirsts = _column(
  canonicalDecompositionTable,
  canonicalDecompositionCount,
  _pairRecordWidth,
  _codePointWidth,
  _codePointWidth,
);

/// The second code point of the mapping of each of [_decomposed], 0 for a
/// singleton.
final List<int> _decompositionSeconds = _column(
  canonicalDecompositionTable,
  canonicalDecompositionCount,
  _pairRecordWidth,
  2 * _codePointWidth,
  _codePointWidth,
);

/// The key of every composition pair, the first code point times
/// [_pairKeyFactor] plus the second, sorted.
final _compositionKeys = List<int>.generate(
  canonicalCompositionCount,
  (index) =>
      _field(canonicalCompositionTable, index * _pairRecordWidth) *
          _pairKeyFactor +
      _field(
        canonicalCompositionTable,
        index * _pairRecordWidth + _codePointWidth,
      ),
  growable: false,
);

/// The primary composite of each of [_compositionKeys].
final List<int> _composites = _column(
  canonicalCompositionTable,
  canonicalCompositionCount,
  _pairRecordWidth,
  2 * _codePointWidth,
  _codePointWidth,
);

/// The first code point of every range of [combiningClassTable], sorted.
final List<int> _classStarts = _column(
  combiningClassTable,
  combiningClassCount,
  _classRecordWidth,
  0,
  _codePointWidth,
);

/// The last code point of each range of [_classStarts].
final List<int> _classEnds = _column(
  combiningClassTable,
  combiningClassCount,
  _classRecordWidth,
  _codePointWidth,
  _codePointWidth,
);

/// The canonical combining class of each range of [_classStarts].
final List<int> _classes = _column(
  combiningClassTable,
  combiningClassCount,
  _classRecordWidth,
  2 * _codePointWidth,
  2,
);

/// The first code point of every range of [nfcQuickCheckTable], sorted.
final List<int> _quickCheckStarts = _column(
  nfcQuickCheckTable,
  nfcQuickCheckCount,
  _quickCheckRecordWidth,
  0,
  _codePointWidth,
);

/// The last code point of each range of [_quickCheckStarts].
final List<int> _quickCheckEnds = _column(
  nfcQuickCheckTable,
  nfcQuickCheckCount,
  _quickCheckRecordWidth,
  _codePointWidth,
  _codePointWidth,
);

/// The NFC quick check of each range of [_quickCheckStarts], 1 for Maybe
/// and 2 for No.
final List<int> _quickChecks = _column(
  nfcQuickCheckTable,
  nfcQuickCheckCount,
  _quickCheckRecordWidth,
  2 * _codePointWidth,
  1,
);

/// The canonical combining class of [codePoint].
///
/// Returns 0 for a starter.
int combiningClassOf(int codePoint) {
  if (codePoint < _firstMark) {
    return 0;
  }
  final int index = _rangeIndexOf(_classStarts, _classEnds, codePoint);
  return index < 0 ? 0 : _classes[index];
}

/// The canonical decomposition mapping of [codePoint], one level deep:
/// its first code point and its second, 0 for a singleton.
///
/// Hangul syllables decompose algorithmically and are not covered.
///
/// Returns `null` when [codePoint] has no canonical decomposition.
(int, int)? canonicalDecompositionOf(int codePoint) {
  if (codePoint < _firstDecomposable) {
    return null;
  }
  final int index = _indexOf(_decomposed, codePoint);
  if (index < 0) {
    return null;
  }
  return (_decompositionFirsts[index], _decompositionSeconds[index]);
}

/// The primary composite that [first] and [second] form.
///
/// Hangul syllables compose algorithmically and are not covered.
///
/// Returns `null` when the pair forms none.
int? primaryCompositeOf(int first, int second) {
  final int index = _indexOf(_compositionKeys, first * _pairKeyFactor + second);
  return index < 0 ? null : _composites[index];
}

/// The NFC quick check of [codePoint] on its own.
///
/// Returns [QuickCheckResult.maybe] for a code point that may combine with
/// the one before it and [QuickCheckResult.no] for one that never occurs in
/// NFC.
QuickCheckResult nfcQuickCheckOf(int codePoint) {
  if (codePoint < _firstMark) {
    return QuickCheckResult.yes;
  }
  final int index = _rangeIndexOf(
    _quickCheckStarts,
    _quickCheckEnds,
    codePoint,
  );
  if (index < 0) {
    return QuickCheckResult.yes;
  }
  return _quickChecks[index] == 1
      ? QuickCheckResult.maybe
      : QuickCheckResult.no;
}

/// Reads the code point field at [offset] of [table].
///
/// Returns its value.
int _field(String table, int offset, [int width = _codePointWidth]) =>
    int.parse(table.substring(offset, offset + width), radix: 16);

/// Reads the field of [width] digits at [offset] of each of the [count]
/// records of [recordWidth] characters in [table].
///
/// Returns the values in record order.
List<int> _column(
  String table,
  int count,
  int recordWidth,
  int offset,
  int width,
) => List<int>.generate(
  count,
  (index) => _field(table, index * recordWidth + offset, width),
  growable: false,
);

/// Finds [value] in the sorted [values] by bisection.
///
/// Returns its index, or -1 when it is not there.
int _indexOf(List<int> values, int value) {
  var low = 0;
  int high = values.length - 1;
  while (low <= high) {
    final int middle = (low + high) ~/ 2;
    final int candidate = values[middle];
    if (candidate == value) {
      return middle;
    }
    if (candidate < value) {
      low = middle + 1;
      continue;
    }
    high = middle - 1;
  }
  return -1;
}

/// Finds the range of [starts] and [ends] that holds [value], the ranges
/// sorted and disjoint.
///
/// Returns its index, or -1 when no range holds [value].
int _rangeIndexOf(List<int> starts, List<int> ends, int value) {
  var low = 0;
  int high = starts.length - 1;
  while (low <= high) {
    final int middle = (low + high) ~/ 2;
    if (value < starts[middle]) {
      high = middle - 1;
      continue;
    }
    if (value > ends[middle]) {
      low = middle + 1;
      continue;
    }
    return middle;
  }
  return -1;
}
