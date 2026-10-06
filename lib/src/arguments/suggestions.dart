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

/// Finds the candidate closest to a mistyped [token].
///
/// The search is bounded: a candidate whose length alone puts it out of
/// reach is skipped, and a comparison stops as soon as it cannot beat the
/// best one so far.
///
/// Returns the closest of [candidates], or `null` when none is close
/// enough to be what was meant.
@internal
String? closestName(String token, Iterable<String> candidates) {
  if (token.length > _longestWorthComparing) {
    return null;
  }
  final int limit = min(_maximumDistance, token.length ~/ _distanceRatio);
  if (limit < 1) {
    return null;
  }
  String? best;
  int bestDistance = limit + 1;
  for (final candidate in candidates) {
    if ((token.length - candidate.length).abs() >= bestDistance) {
      continue;
    }
    final int distance = _boundedDistance(token, candidate, bestDistance);
    if (distance < bestDistance) {
      bestDistance = distance;
      best = candidate;
    }
  }
  return best;
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
