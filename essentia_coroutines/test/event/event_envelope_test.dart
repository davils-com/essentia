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
import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:test/test.dart';

import '../support/user_event.dart';

/// Builds an envelope on the topic `users`, with [id] as its identifier and,
/// unless given, as its correlation identifier.
///
/// Returns the envelope.
EventEnvelope<Event> _envelope({
  UuidV7? id,
  String? key,
  UuidV7? correlationId,
  UuidV7? causationId,
  EventHeaders headers = EventHeaders.empty,
  Event payload = const Registered('u-42'),
}) {
  final UuidV7 identifier = id ?? UuidV7.random();
  return EventEnvelope<Event>(
    id: identifier,
    topic: 'users',
    key: key,
    correlationId: correlationId ?? identifier,
    causationId: causationId,
    headers: headers,
    payload: payload,
  );
}

/// Tests the envelope an event travels in.
void main() {
  test('when it happened is read from the identifier', () {
    final id = UuidV7.random();

    expect(_envelope(id: id).occurredAt, id.instant);
  });

  test('an envelope nothing caused says so', () {
    expect(_envelope().isCaused, isFalse);
    expect(_envelope(causationId: UuidV7.random()).isCaused, isTrue);
  });

  test('two envelopes are the same publication when they carry the same '
      'identifier', () {
    final id = UuidV7.random();
    final EventEnvelope<Event> one = _envelope(
      id: id,
      payload: const Registered('u-1'),
    );
    final EventEnvelope<Event> other = _envelope(
      id: id,
      payload: const Registered('u-2'),
    );

    expect(one, other);
    expect(one.hashCode, other.hashCode);
  });

  test('two publications of the same fact are not the same envelope', () {
    expect(
      _envelope(payload: const Registered('u-1')),
      isNot(_envelope(payload: const Registered('u-1'))),
    );
  });

  group('what it renders as', () {
    test('the plain case names the topic and the payload type', () {
      final rendered = _envelope().toString();

      expect(rendered, contains('topic=users'));
      expect(rendered, contains('payload=Registered)'));
      expect(rendered, isNot(contains('u-42')));
      expect(rendered, isNot(contains('key=')));
      expect(rendered, isNot(contains('headers=')));
      expect(rendered, isNot(contains('causationId=')));
    });

    test('a key, a cause and headers are named when they are there', () {
      final cause = UuidV7.random();
      final rendered = _envelope(
        key: 'u-42',
        causationId: cause,
        headers: EventHeaders.of(const <String, String>{'tenant': 'acme'}),
      ).toString();

      expect(rendered, contains('key=u-42'));
      expect(rendered, contains('causationId=$cause'));
      expect(rendered, contains('headers={tenant=acme}'));
    });

    test("the payload's content is never rendered", () {
      final rendered = _envelope(
        payload: const Registered('user@example.invalid'),
      ).toString();

      expect(rendered, isNot(contains('user@example.invalid')));
    });

    test('a sensitive header is masked', () {
      final EventHeaders headers = EventHeaders.of(const <String, String>{
        'tenant': 'acme',
      }).withHeader('authorization', 'hunter2', sensitive: true);
      final rendered = _envelope(headers: headers).toString();

      expect(rendered, contains('authorization=****'));
      expect(rendered, isNot(contains('hunter2')));
    });
  });
}
