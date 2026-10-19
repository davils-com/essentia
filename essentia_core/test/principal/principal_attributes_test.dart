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

import 'package:essentia_core/src/principal/principal.dart';
import 'package:essentia_core/src/principal/principal_attributes.dart';
import 'package:essentia_core/src/principal/principals.dart';
import 'package:test/test.dart';

/// A value that must never appear in a rendering.
const _placeholder = 'placeholder-value';

/// Covers the attributes of a principal.
void main() {
  test('an empty set has nothing in it and renders as nothing', () {
    expect(PrincipalAttributes.empty.isEmpty, isTrue);
    expect(PrincipalAttributes.empty.toString(), '{}');
  });

  test('names are matched exactly, case included', () {
    final attributes = PrincipalAttributes.of(const <String, String>{
      'sub': 'alice',
    });

    expect(attributes['sub'], 'alice');
    expect(attributes['Sub'], isNull);
    expect(attributes.contains('Sub'), isFalse);
    expect(attributes.contains('sub'), isTrue);
  });

  test('a sensitive value is masked in the rendering and readable through '
      'the accessor', () {
    final PrincipalAttributes attributes = PrincipalAttributes.of(
      const <String, String>{'issuer': 'idp'},
    ).withAttribute('email', _placeholder, sensitive: true);

    expect(attributes.toString(), '{email=****, issuer=idp}');
    expect(attributes['email'], _placeholder);
    expect(attributes.isSensitive('email'), isTrue);
  });

  test('setting a sensitive attribute again without saying so unmasks '
      'it', () {
    final PrincipalAttributes attributes = PrincipalAttributes.empty
        .withAttribute('email', _placeholder, sensitive: true)
        .withAttribute('email', 'x');

    expect(attributes.isSensitive('email'), isFalse);
  });

  test('removing an attribute removes its sensitivity with it', () {
    final PrincipalAttributes attributes = PrincipalAttributes.empty
        .withAttribute('email', _placeholder, sensitive: true)
        .withoutAttribute('email');

    expect(attributes.isEmpty, isTrue);
    expect(attributes.isSensitive('email'), isFalse);
  });

  test('removing an attribute that is not set changes nothing', () {
    final attributes = PrincipalAttributes.of(const <String, String>{
      'issuer': 'idp',
    });

    expect(attributes.withoutAttribute('absent'), same(attributes));
  });

  test('equality covers values and sensitivity', () {
    final plain = PrincipalAttributes.of(const <String, String>{
      'email': _placeholder,
    });
    final PrincipalAttributes masked = PrincipalAttributes.empty.withAttribute(
      'email',
      _placeholder,
      sensitive: true,
    );

    expect(
      plain,
      PrincipalAttributes.of(const <String, String>{'email': _placeholder}),
    );
    expect(
      plain.hashCode,
      PrincipalAttributes.of(const <String, String>{'email': _placeholder})
          .hashCode,
    );
    expect(plain, isNot(masked));
  });

  test('a blank name is refused', () {
    expect(
      () => PrincipalAttributes.of(const <String, String>{' ': 'x'}),
      throwsArgumentError,
    );
    expect(
      () => PrincipalAttributes.empty.withAttribute('', 'x'),
      throwsArgumentError,
    );
  });

  test('the name set refuses to be written through', () {
    final attributes = PrincipalAttributes.of(const <String, String>{
      'a': '1',
      'b': '2',
    });

    expect(attributes.names.clear, throwsUnsupportedError);
    expect(attributes.names, <String>{'a', 'b'});
  });

  test('a principal carrying a sensitive attribute never prints its '
      'value', () {
    final Principal caller = principal('alice', (it) {
      it.attribute('email', _placeholder, sensitive: true);
    });

    expect(caller.toString(), isNot(contains(_placeholder)));
  });
}
