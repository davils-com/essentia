/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
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
    test('the plain case names the topic and the payload', () {
      final rendered = _envelope().toString();

      expect(rendered, contains('topic=users'));
      expect(rendered, contains('payload=Registered(userId=u-42)'));
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
