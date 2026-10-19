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

import 'package:essentia_core/essentia_core.dart';
import 'package:test/test.dart';

/// How long the very long input is.
const _longInputLength = 5000;

/// The length every refusal stays under.
const _shortMessageLimit = 80;

/// Runs [parse] on [text], which is expected to be refused.
///
/// Returns the [FormatException] it threw.
///
/// Throws a [StateError] if [text] was accepted.
FormatException _refusalOf(Object Function(String) parse, String text) {
  try {
    parse(text);
  } on FormatException catch (refusal) {
    return refusal;
  }
  throw StateError('Expected a FormatException, but the text was accepted');
}

/// Tests that a refused identifier is never quoted back, since it may be a
/// session token or a capability link.
void main() {
  test('a very long input is refused with a short message that does not '
      'quote it', () {
    final String input = 'x' * _longInputLength;

    final FormatException refusal = _refusalOf(Uuid.parse, input);

    expect(refusal.message, 'Not a UUID: $_longInputLength characters, not 36');
    expect(refusal.message.length, lessThan(_shortMessageLimit));
    expect(refusal.source, isNull);
    expect(refusal.toString(), isNot(contains(input)));
  });

  test('a token of the right length is refused without being quoted', () {
    const placeholder = 'placeholder-session-value-0000000000';

    final FormatException refusal = _refusalOf(UuidV4.parse, placeholder);

    expect(refusal.toString(), isNot(contains(placeholder)));
  });

  test('a well-formed identifier of the wrong version is refused without '
      'being quoted', () {
    final version7 = UuidV7.random().toString();

    final FormatException refusal = _refusalOf(UuidV4.parse, version7);

    expect(refusal.toString(), isNot(contains(version7)));
    expect(
      refusal.message,
      'Not a well-formed UUID of a version Essentia mints',
    );
  });

  test('every parser refuses the same way', () {
    const text = 'not-a-uuid';

    for (final parse in <Object Function(String)>[
      Uuid.parse,
      UuidV4.parse,
      UuidV7.parse,
    ]) {
      final FormatException refusal = _refusalOf(parse, text);

      expect(refusal.message, 'Not a UUID: 10 characters, not 36');
      expect(refusal.toString(), isNot(contains(text)));
    }
  });
}
