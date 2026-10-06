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

/// Finds the candidate closest to a mistyped [token].
///
/// Returns the closest of [candidates], or `null` when none is close
/// enough to be what was meant.
@internal
String? closestName(String token, Iterable<String> candidates) {
  final int limit = min(_maximumDistance, token.length ~/ _distanceRatio);
  if (limit < 1) {
    return null;
  }
  String? best;
  int bestDistance = limit + 1;
  for (final candidate in candidates) {
    final int distance = _editDistance(token, candidate);
    if (distance < bestDistance) {
      bestDistance = distance;
      best = candidate;
    }
  }
  return best;
}

/// Counts the insertions, deletions and substitutions that turn [left]
/// into [right].
///
/// Returns the Levenshtein distance.
int _editDistance(String left, String right) {
  var previous = List<int>.generate(right.length + 1, (index) => index);
  var current = List<int>.filled(right.length + 1, 0);
  for (var i = 1; i <= left.length; i++) {
    current[0] = i;
    for (var j = 1; j <= right.length; j++) {
      final cost = left[i - 1] == right[j - 1] ? 0 : 1;
      final int substitution = previous[j - 1] + cost;
      final int deletion = previous[j] + 1;
      final int insertion = current[j - 1] + 1;
      current[j] = min(substitution, min(deletion, insertion));
    }
    final swap = previous;
    previous = current;
    current = swap;
  }
  return previous[right.length];
}
