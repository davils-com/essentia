/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/version/internal/interval_algebra.dart';
import 'package:essentia_core/src/version/internal/partial.dart';
import 'package:essentia_core/src/version/internal/shorthands.dart';
import 'package:essentia_core/src/version/internal/version_steps.dart';
import 'package:essentia_core/src/version/semantic_version.dart';
import 'package:essentia_core/src/version/version_interval.dart';
import 'package:meta/meta.dart';

/// The operator a comparator of a range starts with.
///
/// Listed so that a longer symbol is tried before the shorter one it
/// starts with: `>=` before `>`.
@internal
enum Operator {
  /// At least the version.
  greaterOrEqual('>='),

  /// At most the version.
  lessOrEqual('<='),

  /// Above the version.
  greater('>'),

  /// Below the version.
  less('<'),

  /// Exactly the version.
  equal('='),

  /// The version and the patches after it.
  tilde('~'),

  /// The version and whatever can stand in for it.
  caret('^');

  /// Creates the operator written [symbol].
  const Operator(this.symbol);

  /// How the operator is written.
  final String symbol;
}

/// The interval a comparator of [operator], or of none, and [partial]
/// means.
///
/// Returns the interval, or `null` when no version lies inside it.
@internal
VersionInterval? intervalFor(Operator? operator, Partial partial) =>
    switch (operator) {
      null || Operator.equal => _exactInterval(partial),
      Operator.greaterOrEqual => _atLeastInterval(partial),
      Operator.greater => _aboveInterval(partial),
      Operator.less => _belowInterval(partial),
      Operator.lessOrEqual => _atMostInterval(partial),
      Operator.tilde => tildeInterval(partial),
      Operator.caret => caretInterval(partial),
    };

/// The interval `=partial` means: the version, or its whole line.
///
/// Returns the interval, or `null` when no version lies inside it.
VersionInterval? _exactInterval(Partial partial) {
  if (partial.isAny) {
    return everything;
  }
  return interval(partial.lowest(), partial.firstAbove());
}

/// The interval `>=partial` means.
///
/// Returns the interval, or `null` when no version lies inside it.
VersionInterval? _atLeastInterval(Partial partial) {
  if (partial.isAny) {
    return everything;
  }
  return interval(partial.lowest(), null);
}

/// The interval `>partial` means: above the version, or above its whole
/// line.
///
/// Returns the interval, or `null` when no version lies inside it.
VersionInterval? _aboveInterval(Partial partial) {
  if (partial.isAny) {
    return null;
  }
  final SemanticVersion? complete = partial.version;
  if (complete != null) {
    return interval(complete, null, startExclusive: true);
  }
  final SemanticVersion? next = floorAbove(partial.numbers);
  if (next == null) {
    return null;
  }
  return interval(next.release(), null);
}

/// The interval `<partial` means: below the version, or below its whole
/// line.
///
/// Returns the interval, or `null` when no version lies inside it.
VersionInterval? _belowInterval(Partial partial) {
  if (partial.isAny) {
    return null;
  }
  return interval(null, partial.version ?? preReleaseFloor(partial.numbers));
}

/// The interval `<=partial` means: up to the version, or up to the end of
/// its whole line.
///
/// Returns the interval, or `null` when no version lies inside it.
VersionInterval? _atMostInterval(Partial partial) {
  if (partial.isAny) {
    return everything;
  }
  return interval(null, partial.firstAbove());
}
