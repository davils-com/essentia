/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Whether [a] and [b] hold equal values in order, lists compared element
/// by element.
bool sameIcsValues(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index += 1) {
    final Object? left = a[index];
    final Object? right = b[index];
    if (left is List<Object?> && right is List<Object?>) {
      if (!sameIcsValues(left, right)) {
        return false;
      }
      continue;
    }
    if (left != right) {
      return false;
    }
  }
  return true;
}

/// A hash of [values], lists hashed element by element.
int hashIcsValues(List<Object?> values) => Object.hashAll(
  values.map((value) => value is List<Object?> ? hashIcsValues(value) : value),
);
