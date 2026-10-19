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
