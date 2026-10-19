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

import '../support/topics.dart';

/// Resolves the audit topic against [bus], which does not carry it.
///
/// Returns the declared names the resulting error carries.
Set<String> _declaredNamesOfFailedLookup(EventBus bus) {
  final captured = <Set<String>>[];
  expect(
    () => bus.topic(audit),
    throwsA(
      isA<TopicNotDeclaredError>().having(
        (failure) => failure.declared,
        'declared',
        predicate<Set<String>>((names) {
          captured.add(names);
          return names.isNotEmpty;
        }, 'not empty'),
      ),
    ),
  );
  return captured.single;
}

/// Tests that the names a bus hands out cannot be changed from outside.
void main() {
  test('the topic names refuse a removal and the bus still resolves the '
      'topic', () {
    final EventBus bus = eventBus((it) {
      it
        ..topic(users)
        ..topic(audit);
    });

    expect(() => bus.topicNames.remove('users'), throwsUnsupportedError);

    expect(bus.topicNames, <String>['users', 'audit']);
    expect(bus.topic(users).name, 'users');
    bus.dispose();
  });

  test('the declared names an error carries refuse a mutation', () {
    final EventBus bus = eventBus((it) => it.topic(users));
    final Set<String> declared = _declaredNamesOfFailedLookup(bus);

    expect(declared.clear, throwsUnsupportedError);

    expect(declared, <String>{'users'});
    expect(bus.topicNames, <String>{'users'});
    bus.dispose();
  });
}
