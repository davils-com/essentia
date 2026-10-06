/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:math';

/// The lowercase letters `a` to `z`.
const lowercaseLetters = 'abcdefghijklmnopqrstuvwxyz';

/// Letters of both cases and the decimal digits.
const alphanumerics = '${lowercaseLetters}ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

/// Draws a text of [minimum] to [maximum] characters of [alphabet] from
/// [random].
///
/// Returns the text.
String randomText(
  Random random,
  String alphabet, {
  required int minimum,
  required int maximum,
}) {
  final int length = minimum + random.nextInt(maximum - minimum + 1);
  return String.fromCharCodes(
    List<int>.generate(
      length,
      (_) => alphabet.codeUnitAt(random.nextInt(alphabet.length)),
    ),
  );
}
