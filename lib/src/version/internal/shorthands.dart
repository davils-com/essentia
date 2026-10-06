/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/version/internal/interval_algebra.dart';
import 'package:essentia/src/version/internal/partial.dart';
import 'package:essentia/src/version/internal/version_steps.dart';
import 'package:essentia/src/version/semantic_version.dart';
import 'package:essentia/src/version/version_interval.dart';
import 'package:meta/meta.dart';

/// How many numbers of a tilde range stay fixed.
const _tildePrefix = 2;

/// The interval `~partial` means: at least [partial], below the next
/// minor line, or the next major one when only the major was given.
///
/// Returns the interval, or `null` when no version lies inside it.
@internal
VersionInterval? tildeInterval(Partial partial) {
  if (partial.isAny) {
    return everything;
  }
  return interval(
    partial.lowest(),
    floorAbove(partial.numbers.take(_tildePrefix).toList()),
  );
}

/// The interval `^partial` means: at least [partial], below the line after
/// its first number that is not zero.
///
/// Returns the interval, or `null` when no version lies inside it.
@internal
VersionInterval? caretInterval(Partial partial) {
  if (partial.isAny) {
    return everything;
  }
  return interval(partial.lowest(), floorAbove(_caretPrefix(partial.numbers)));
}

/// The interval `from - to` means: at least [from], and every version of
/// the line [to] names.
///
/// Returns the interval, or `null` when no version lies inside it.
@internal
VersionInterval? hyphenInterval(Partial from, Partial to) {
  final SemanticVersion? start = from.isAny ? null : from.lowest();
  final SemanticVersion? end = to.isAny ? null : to.firstAbove();
  return interval(start, end);
}

/// The numbers of [numbers] up to and including the first that is not
/// zero, which are the ones a caret range keeps fixed.
///
/// Returns those numbers, or all of them when every one is zero.
List<int> _caretPrefix(List<int> numbers) {
  final int firstNonZero = numbers.indexWhere((number) => number != 0);
  if (firstNonZero < 0) {
    return numbers;
  }
  return numbers.take(firstNonZero + 1).toList();
}
