/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:test/test.dart';

import '../support/audit_event.dart';
import '../support/user_event.dart';

/// Tests the key that names a topic and carries its payload type.
void main() {
  test('a key names a topic and carries its payload type', () {
    final key = TopicKey<UserEvent>('users');

    expect(key.name, 'users');
    expect(key.eventType, UserEvent);
  });

  test('a key renders its name and its payload type', () {
    expect(
      TopicKey<UserEvent>('users').toString(),
      'TopicKey(users: UserEvent)',
    );
    expect(
      TopicKey<AuditEvent>('audit').toString(),
      'TopicKey(audit: AuditEvent)',
    );
  });

  test('two keys are the same key when name and payload type agree', () {
    final one = TopicKey<UserEvent>('users');

    expect(one, TopicKey<UserEvent>('users'));
    expect(one.hashCode, TopicKey<UserEvent>('users').hashCode);
    expect(one, isNot(TopicKey<UserEvent>('audit')));
  });

  test('keys naming one topic with different payloads are different', () {
    final one = TopicKey<UserEvent>('users');
    final other = TopicKey<AuditEvent>('users');

    expect(one, isNot(other));
    expect(<TopicKey<Event>>{one, other}, hasLength(2));
  });

  group('a blank name is refused where the key is written', () {
    test('when it is empty', () {
      expect(() => TopicKey<UserEvent>(''), throwsArgumentError);
    });

    test('when it is only whitespace', () {
      expect(() => TopicKey<UserEvent>('   '), throwsArgumentError);
      expect(() => TopicKey<UserEvent>('\t\n'), throwsArgumentError);
    });
  });

  test('a name with surrounding whitespace is kept as written', () {
    expect(TopicKey<UserEvent>(' users ').name, ' users ');
  });
}
