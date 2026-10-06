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

import '../support/audit_event.dart';
import '../support/recording_listener.dart';
import '../support/user_event.dart';

/// Declares a bus through [block] without starting it.
///
/// Returns the builder, ready to be validated or built.
EventBusBuilder _declare(void Function(EventBusBuilder it) block) =>
    EventBusBuilder().apply(block);

/// Tests how a bus and its topics are declared and validated.
void main() {
  test('a declared topic is described exactly as it was written', () {
    final listener = RecordingListener();
    final EventBusBuilder builder = _declare((it) {
      it.topic(TopicKey<UserEvent>('users'), (it) {
        it
          ..replay = 10
          ..bufferCapacity = 256
          ..partitions = 4
          ..requiresKey = true
          ..overflow = OverflowPolicy.dropOldest
          ..listener = listener;
      });
    });

    final EventTopicData<Event> topic = builder.build().topics.single;

    expect(topic.name, 'users');
    expect(topic.eventType, UserEvent);
    expect(topic.replay, 10);
    expect(topic.bufferCapacity, 256);
    expect(topic.partitions, 4);
    expect(topic.requiresKey, isTrue);
    expect(topic.overflow, OverflowPolicy.dropOldest);
    expect(topic.listener, same(listener));
  });

  test('a topic starts from the bus defaults and overrides only what it '
      'says', () {
    final EventBusBuilder builder = _declare((it) {
      it
        ..bufferCapacity = 256
        ..partitions = 4
        ..overflow = OverflowPolicy.dropOldest
        ..topic(TopicKey<UserEvent>('users'), (it) => it.partitions = 8)
        ..topic(TopicKey<AuditEvent>('audit'));
    });

    final List<EventTopicData<Event>> topics = builder.build().topics;
    final EventTopicData<Event> users = topics.first;
    final EventTopicData<Event> audit = topics.last;

    expect(users.partitions, 8);
    expect(users.bufferCapacity, 256);
    expect(users.overflow, OverflowPolicy.dropOldest);
    expect(audit.partitions, 4);
    expect(audit.bufferCapacity, 256);
  });

  test('changing a default afterwards does not reach a topic already '
      'declared', () {
    final EventBusBuilder builder = _declare((it) {
      it
        ..partitions = 2
        ..topic(TopicKey<UserEvent>('users'))
        ..partitions = 16
        ..topic(TopicKey<AuditEvent>('audit'));
    });

    final List<EventTopicData<Event>> topics = builder.build().topics;

    expect(topics.first.partitions, 2);
    expect(topics.last.partitions, 16);
  });

  test('topics keep the order they were declared in', () {
    final EventBusBuilder builder = _declare((it) {
      it
        ..topic(TopicKey<AuditEvent>('audit'))
        ..topic(TopicKey<UserEvent>('users'));
    });

    expect(builder.build().topics.map((topic) => topic.name), <String>[
      'audit',
      'users',
    ]);
  });

  test('the defaults are the ones a bus that says nothing gets', () {
    final EventTopicData<Event> topic = _declare(
      (it) => it.topic(TopicKey<UserEvent>('users')),
    ).build().topics.single;

    expect(topic.replay, 0);
    expect(topic.bufferCapacity, 64);
    expect(topic.partitions, 1);
    expect(topic.requiresKey, isFalse);
    expect(topic.listener, same(EventListener.none));
    expect(topic.interceptors, isEmpty);
  });

  test('the default overflow policy is the one that never discards an '
      'envelope', () {
    final EventTopicData<Event> topic = _declare(
      (it) => it.topic(TopicKey<UserEvent>('users')),
    ).build().topics.single;

    expect(topic.overflow, OverflowPolicy.suspend);
  });

  test('a bus with no topic is refused', () {
    final ValidationReport report = _declare((it) {}).validate();

    expect(report.isValid, isFalse);
    expect(report.errors.single.code, EventViolationCodes.noTopics);
    expect(report.errors.single.path.toString(), 'topics');
  });

  test('a bus with three invalid topics reports all three, each at its own '
      'path', () {
    final ValidationReport report = _declare((it) {
      it
        ..topic(TopicKey<UserEvent>('a'), (it) => it.replay = -1)
        ..topic(TopicKey<AuditEvent>('b'), (it) => it.partitions = 0)
        ..topic(TopicKey<UserEvent>('c'), (it) => it.bufferCapacity = -8);
    }).validate();

    expect(report.isValid, isFalse);
    expect(report.errors.map((error) => error.path.toString()), <String>[
      'topics[0].replay',
      'topics[1].partitions',
      'topics[2].bufferCapacity',
    ]);
    expect(report.errors.map((error) => error.code), <ViolationCode>[
      EventViolationCodes.invalidReplay,
      EventViolationCodes.invalidPartitions,
      EventViolationCodes.invalidBuffer,
    ]);
  });

  test('one topic with several mistakes reports every one of them', () {
    final ValidationReport report = _declare((it) {
      it.topic(TopicKey<UserEvent>('users'), (it) {
        it
          ..replay = -1
          ..partitions = -2
          ..bufferCapacity = -3;
      });
    }).validate();

    expect(report.errors.map((error) => error.path.toString()), <String>[
      'topics[0].replay',
      'topics[0].bufferCapacity',
      'topics[0].partitions',
    ]);
  });

  test('a topic that cannot buffer and will not wait is refused', () {
    final ValidationReport report = _declare((it) {
      it.topic(TopicKey<UserEvent>('users'), (it) {
        it
          ..bufferCapacity = 0
          ..overflow = OverflowPolicy.dropOldest;
      });
    }).validate();

    expect(report.isValid, isFalse);
    expect(report.errors.single.code, EventViolationCodes.invalidBuffer);
  });

  test('a topic that cannot buffer but does wait is allowed', () {
    final ValidationReport report = _declare((it) {
      it.topic(TopicKey<UserEvent>('users'), (it) {
        it
          ..bufferCapacity = 0
          ..overflow = OverflowPolicy.suspend;
      });
    }).validate();

    expect(report.isValid, isTrue);
  });

  test('demanding a key on a single partition is a warning and starts '
      'anyway', () {
    final ValidationReport report = _declare((it) {
      it.topic(TopicKey<UserEvent>('users'), (it) => it.requiresKey = true);
    }).validate();

    expect(report.isValid, isTrue);
    final Violation warning = report.warnings.single;
    expect(warning.severity, Severity.warning);
    expect(warning.code, EventViolationCodes.keyWithoutPartitions);
    expect(warning.path.toString(), 'topics[0].requiresKey');
  });

  test('demanding a key on a partitioned topic says nothing', () {
    final ValidationReport report = _declare((it) {
      it.topic(TopicKey<UserEvent>('users'), (it) {
        it
          ..partitions = 4
          ..requiresKey = true;
      });
    }).validate();

    expect(report.violations, isEmpty);
  });

  test('starting a bus from a wrong declaration throws every problem at '
      'once', () {
    expect(
      () => eventBus((it) {
        it.topic(TopicKey<UserEvent>('users'), (it) {
          it
            ..replay = -1
            ..partitions = 0;
        });
      }),
      throwsA(
        isA<ValidationException>().having(
          (failure) => failure.report.errors.map((error) => error.code),
          'codes',
          <ViolationCode>[
            EventViolationCodes.invalidReplay,
            EventViolationCodes.invalidPartitions,
          ],
        ),
      ),
    );
  });

  test('a bus whose declaration only warns starts', () {
    final EventBus bus = eventBus((it) {
      it.topic(TopicKey<UserEvent>('users'), (it) => it.requiresKey = true);
    });

    expect(bus.state, BusState.running);
    bus.dispose();
  });

  group('what can only be a mistake in the source is refused on the '
      'spot', () {
    test('a blank name, where the key is written', () {
      expect(() => TopicKey<UserEvent>('   '), throwsArgumentError);
    });

    test('a topic declared twice, whatever the payload type', () {
      expect(
        () => _declare((it) {
          it
            ..topic(TopicKey<UserEvent>('users'))
            ..topic(TopicKey<AuditEvent>('users'));
        }),
        throwsArgumentError,
      );
    });

    test('a topic declared twice when the bus is started', () {
      expect(
        () => eventBus((it) {
          it
            ..topic(TopicKey<UserEvent>('users'))
            ..topic(TopicKey<UserEvent>('users'));
        }),
        throwsArgumentError,
      );
    });
  });

  test('a failed declaration names what it was validating', () {
    final ValidationReport report = _declare((it) {
      it.topic(TopicKey<UserEvent>('users'), (it) => it.replay = -1);
    }).validate();

    expect(report.subject, 'event bus');
  });
}
