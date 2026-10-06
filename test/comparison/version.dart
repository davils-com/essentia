/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// A version number of the tests' own, comparable by its [number] only.
final class Version implements Comparable<Version> {
  /// Creates the version with [number].
  const Version(this.number);

  /// The number that orders versions.
  final int number;

  /// Compares this version with [other] by their numbers.
  ///
  /// Returns a negative number, zero or a positive number when this
  /// version comes before, with or after [other].
  @override
  int compareTo(Version other) => number.compareTo(other.number);
}
