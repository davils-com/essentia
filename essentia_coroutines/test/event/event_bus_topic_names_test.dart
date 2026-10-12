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
