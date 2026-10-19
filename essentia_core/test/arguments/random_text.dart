/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
