/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:math';

import 'package:meta/meta.dart';

/// The largest edit distance a suggestion may have.
const _maximumDistance = 3;

/// How many characters of a token allow one edit.
const _distanceRatio = 3;

/// The longest token worth comparing against the declared names.
///
/// A token longer than this is not a mistyped name, and comparing it would
/// cost time proportional to its length for every candidate.
const _longestWorthComparing = 64;

/// Finds what a mistyped name was meant to be: the "did you mean" of an
/// error message.
///
/// ```dart
/// '--prot'.closestIn(<String>['--port', '--host']); // --port
/// 'tagz'.closestIn(<String>['name', 'tags']);       // tags
/// ```
///
/// A name is close when few insertions, deletions and substitutions turn
/// one into the other: at most one for every three characters, and never
/// more than three. A name of fewer than three characters has no close
/// candidates, and neither has one longer than 64 characters, which is not
/// a mistyped name and would cost time to compare.
extension StringSimilarity on String {
  /// Finds the candidate closest to this text.
  ///
  /// The search is bounded: a candidate whose length alone puts it out of
  /// reach is skipped, and a comparison stops as soon as it cannot beat
  /// the best one so far. Of two candidates equally close, the first wins.
  ///
  /// Returns the closest of [candidates], or `null` when none is close
  /// enough to be what was meant.
  @useResult
  String? closestIn(Iterable<String> candidates) {
    if (length > _longestWorthComparing) {
      return null;
    }
    final int limit = min(_maximumDistance, length ~/ _distanceRatio);
    if (limit < 1) {
      return null;
    }
    String? best;
    int bestDistance = limit + 1;
    for (final candidate in candidates) {
      if ((length - candidate.length).abs() >= bestDistance) {
        continue;
      }
      final int distance = _boundedDistance(this, candidate, bestDistance);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = candidate;
      }
    }
    return best;
  }
}

/// Counts the insertions, deletions and substitutions that turn [left]
/// into [right], giving up once the count cannot stay below [cutoff].
///
/// Returns the Levenshtein distance, or [cutoff] when it is at least that.
int _boundedDistance(String left, String right, int cutoff) {
  var previous = List<int>.generate(right.length + 1, (index) => index);
  var current = List<int>.filled(right.length + 1, 0);
  for (var i = 1; i <= left.length; i++) {
    current[0] = i;
    var rowMinimum = i;
    for (var j = 1; j <= right.length; j++) {
      final cost = left[i - 1] == right[j - 1] ? 0 : 1;
      final int substitution = previous[j - 1] + cost;
      final int deletion = previous[j] + 1;
      final int insertion = current[j - 1] + 1;
      current[j] = min(substitution, min(deletion, insertion));
      rowMinimum = min(rowMinimum, current[j]);
    }
    if (rowMinimum >= cutoff) {
      return cutoff;
    }
    final swap = previous;
    previous = current;
    current = swap;
  }
  return previous[right.length];
}
