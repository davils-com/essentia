/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// The kinds of identifier Essentia mints, as numbered by RFC 9562.
///
/// The RFC defines eight versions. Essentia implements the two that are
/// worth using in new code and does not pretend to be a general parser for
/// the rest: a version 1 identifier leaks a MAC address, a version 3 or 5
/// identifier is a hash of something the caller already has, and a version
/// 6 or 8 identifier is for people who know exactly why they want one.
enum UuidVersion {
  /// Random. 122 bits of it, and nothing else.
  ///
  /// The one to use when an identifier should say nothing at all about when
  /// or where it was minted. Two of them sort in an order that means
  /// nothing.
  random(4),

  /// Time-ordered. The leading 48 bits are the millisecond it was minted
  /// in.
  ///
  /// The one to use for anything that will be stored, logged or replayed,
  /// because sorting a set of them sorts them by when they happened.
  timeOrdered(7);

  /// Creates the version whose digit is [number].
  const UuidVersion(this.number);

  /// The version digit, as it appears in the text form.
  final int number;

  /// Looks a version up by its digit.
  ///
  /// Returns the version, or `null` for a digit Essentia does not mint.
  @internal
  static UuidVersion? forNumber(int number) {
    for (final UuidVersion version in values) {
      if (version.number == number) {
        return version;
      }
    }
    return null;
  }
}
