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

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:test/test.dart';

/// Tests the headers that travel beside a payload.
void main() {
  test('an empty set has nothing in it and renders as nothing', () {
    expect(EventHeaders.empty.isEmpty, isTrue);
    expect(EventHeaders.empty.names, isEmpty);
    expect(EventHeaders.empty.toString(), '{}');
    expect(EventHeaders.empty['absent'], isNull);
  });

  test('building from nothing is the empty set', () {
    expect(EventHeaders.of(const <String, String>{}), same(EventHeaders.empty));
  });

  test('a name is the same header however it is capitalised', () {
    final headers = EventHeaders.of(const <String, String>{
      'Traceparent': '00-abc-def-01',
    });

    expect(headers['traceparent'], '00-abc-def-01');
    expect(headers['TRACEPARENT'], '00-abc-def-01');
    expect(headers.contains('TraceParent'), isTrue);
    expect(headers.names, <String>{'traceparent'});
  });

  test('setting a name again replaces it rather than adding a second', () {
    final EventHeaders headers = EventHeaders.of(const <String, String>{
      'tenant': 'acme',
    }).withHeader('TENANT', 'globex');

    expect(headers['tenant'], 'globex');
    expect(headers.names, hasLength(1));
  });

  test('a repeated name in one call keeps the last value', () {
    final headers = EventHeaders.of(const <String, String>{
      'tenant': 'acme',
      'TENANT': 'globex',
    });

    expect(headers['tenant'], 'globex');
    expect(headers.names, hasLength(1));
  });

  test('headers are immutable, so adding to a set leaves the original '
      'alone', () {
    final original = EventHeaders.of(const <String, String>{'tenant': 'acme'});
    final EventHeaders extended = original.withHeader('region', 'eu');

    expect(original.names, <String>{'tenant'});
    expect(extended.names, <String>{'tenant', 'region'});
  });

  test('the names cannot be changed from outside', () {
    final headers = EventHeaders.of(const <String, String>{'tenant': 'acme'});

    expect(() => headers.names.add('region'), throwsUnsupportedError);
  });

  test('removing a header that is not there changes nothing', () {
    final headers = EventHeaders.of(const <String, String>{'tenant': 'acme'});

    expect(headers.withoutHeader('absent'), same(headers));
    expect(headers.withoutHeader('TENANT').isEmpty, isTrue);
  });

  group('a sensitive value never appears in what Essentia renders', () {
    test('it is masked in the rendering and readable through the '
        'accessor', () {
      final EventHeaders headers = EventHeaders.of(const <String, String>{
        'tenant': 'acme',
      }).withHeader('authorization', 'hunter2', sensitive: true);

      expect(headers.toString(), '{authorization=****, tenant=acme}');
      expect(headers['authorization'], 'hunter2');
      expect(headers.isSensitive('authorization'), isTrue);
      expect(headers.isSensitive('Authorization'), isTrue);
      expect(headers.isSensitive('tenant'), isFalse);
    });

    test('setting it again without saying so stops masking it', () {
      final EventHeaders headers = EventHeaders.empty
          .withHeader('authorization', 'hunter2', sensitive: true)
          .withHeader('authorization', 'hunter3');

      expect(headers.isSensitive('authorization'), isFalse);
    });

    test('removing it forgets that it was sensitive', () {
      final EventHeaders headers = EventHeaders.empty
          .withHeader('authorization', 'hunter2', sensitive: true)
          .withoutHeader('authorization')
          .withHeader('authorization', 'hunter3');

      expect(headers.isSensitive('authorization'), isFalse);
    });

    test('it stays masked when it is laid over another set', () {
      final EventHeaders secret = EventHeaders.empty.withHeader(
        'authorization',
        'hunter2',
        sensitive: true,
      );
      final EventHeaders combined =
          EventHeaders.of(const <String, String>{'tenant': 'acme'}) + secret;

      expect(combined.toString(), '{authorization=****, tenant=acme}');
    });

    test('it stays masked when another set is laid over it', () {
      final EventHeaders secret = EventHeaders.empty.withHeader(
        'authorization',
        'hunter2',
        sensitive: true,
      );
      final EventHeaders combined =
          secret + EventHeaders.of(const <String, String>{'tenant': 'acme'});

      expect(combined.toString(), '{authorization=****, tenant=acme}');
    });

    test('something laid on top of it brings its own marking', () {
      final EventHeaders secret = EventHeaders.empty.withHeader(
        'authorization',
        'hunter2',
        sensitive: true,
      );
      final EventHeaders combined =
          secret +
          EventHeaders.of(const <String, String>{'authorization': 'public'});

      expect(combined.isSensitive('authorization'), isFalse);
      expect(combined.toString(), '{authorization=public}');
    });
  });

  test('laying one set over another lets the newer one win', () {
    final base = EventHeaders.of(const <String, String>{
      'tenant': 'acme',
      'region': 'eu',
    });
    final overlay = EventHeaders.of(const <String, String>{'region': 'us'});
    final EventHeaders combined = base + overlay;

    expect(combined['tenant'], 'acme');
    expect(combined['region'], 'us');
  });

  test('laying an empty set over one changes nothing', () {
    final headers = EventHeaders.of(const <String, String>{'tenant': 'acme'});

    expect(headers + EventHeaders.empty, headers);
    expect(EventHeaders.empty + headers, headers);
  });

  test('two sets are equal when they carry the same values and the same '
      'markings', () {
    final one = EventHeaders.of(const <String, String>{'tenant': 'acme'});
    final same = EventHeaders.of(const <String, String>{'TENANT': 'acme'});
    final EventHeaders masked = EventHeaders.empty.withHeader(
      'tenant',
      'acme',
      sensitive: true,
    );

    expect(one, same);
    expect(one.hashCode, same.hashCode);
    expect(one, isNot(masked));
    expect(
      one,
      isNot(EventHeaders.of(const <String, String>{'tenant': 'globex'})),
    );
  });

  test('a blank name is refused', () {
    expect(
      () => EventHeaders.of(const <String, String>{'  ': 'value'}),
      throwsArgumentError,
    );
    expect(
      () => EventHeaders.empty.withHeader('', 'value'),
      throwsArgumentError,
    );
  });
}
