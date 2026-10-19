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

import 'dart:async';

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:test/test.dart';

import '../support/audit_event.dart';
import '../support/topics.dart';
import '../support/user_event.dart';

/// Runs [block] against a bus carrying only the topic of user events, and
/// disposes of the bus afterwards whatever happens.
Future<void> _withBus(Future<void> Function(EventBus bus) block) async {
  final EventBus bus = eventBus((it) => it.topic(users));
  try {
    await block(bus);
  } finally {
    bus.dispose();
  }
}

/// Lets every task that is ready run, so that what was published has been
/// taken off its partition.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

/// Tests publishing to and subscribing on a topic.
void main() {
  test('a subscriber receives what is published after it attaches', () async {
    await _withBus((bus) async {
      final received = <String>[];
      final EventSubscription subscription = bus
          .topic(users)
          .subscribe((envelope) => received.add('${envelope.payload}'));
      await subscription.awaitReady();

      await bus.topic(users).publish(const Registered('u-1'));
      await bus.topic(users).publish(const Deleted('u-2', 'asked'));
      await bus.drain();
      await subscription.join();

      expect(received, <String>[
        'Registered(userId=u-1)',
        'Deleted(userId=u-2, reason=asked)',
      ]);
    });
  });

  test('the envelope carries the topic, the key and the payload', () async {
    await _withBus((bus) async {
      final EventEnvelope<UserEvent>? envelope = await bus
          .topic(users)
          .publish(
            const Registered('u-1'),
            key: 'u-1',
            headers: EventHeaders.of(const <String, String>{'tenant': 'acme'}),
          );

      expect(envelope, isNotNull);
      expect(envelope!.topic, 'users');
      expect(envelope.key, 'u-1');
      expect(envelope.payload, const Registered('u-1'));
      expect(envelope.headers['tenant'], 'acme');
      expect(envelope.correlationId, envelope.id);
      expect(envelope.causationId, isNull);
      expect(envelope.isCaused, isFalse);
    });
  });

  test('publishing without waiting hands back the envelope too', () async {
    await _withBus((bus) async {
      final EventEnvelope<UserEvent>? envelope = bus
          .topic(users)
          .tryPublish(const Registered('u-1'), key: 'u-1');

      expect(envelope, isNotNull);
      expect(envelope!.key, 'u-1');
      expect(envelope.correlationId, envelope.id);
    });
  });

  test('publishing from inside a consumer joins the chain being '
      'handled', () async {
    final EventBus bus = eventBus((it) {
      it
        ..topic(users)
        ..topic(audit);
    });
    final recorded = Completer<EventEnvelope<AuditEvent>>();

    await bus.topic(audit).subscribe(recorded.complete).awaitReady();
    await bus.topic(users).subscribe((envelope) async {
      await bus.topic(audit).publish(const AuditEvent('registered'));
    }).awaitReady();

    final EventEnvelope<UserEvent>? cause = await bus
        .topic(users)
        .publish(const Registered('u-1'));
    final EventEnvelope<AuditEvent> effect = await recorded.future;

    expect(effect.correlationId, cause?.correlationId);
    expect(effect.causationId, cause?.id);
    expect(effect.isCaused, isTrue);
    bus.dispose();
  });

  test('publishing without waiting from inside a consumer joins the chain '
      'too', () async {
    final EventBus bus = eventBus((it) {
      it
        ..topic(users)
        ..topic(audit);
    });
    final recorded = Completer<EventEnvelope<AuditEvent>>();

    await bus.topic(audit).subscribe(recorded.complete).awaitReady();
    await bus.topic(users).subscribe((envelope) {
      bus.topic(audit).tryPublish(const AuditEvent('registered'));
    }).awaitReady();

    final EventEnvelope<UserEvent>? cause = await bus
        .topic(users)
        .publish(const Registered('u-1'));
    final EventEnvelope<AuditEvent> effect = await recorded.future;

    expect(effect.correlationId, cause?.correlationId);
    expect(effect.causationId, cause?.id);
    bus.dispose();
  });

  test('a chain keeps its correlation over every step', () async {
    final EventBus bus = eventBus((it) {
      it
        ..topic(users)
        ..topic(audit);
    });
    final recorded = Completer<EventEnvelope<AuditEvent>>();

    await bus.topic(audit).subscribe(recorded.complete).awaitReady();
    await bus.topic(users).subscribe((envelope) async {
      switch (envelope.payload) {
        case Registered(:final String userId):
          await bus.topic(users).publish(Deleted(userId, 'expired'));
        case Deleted():
          await bus.topic(audit).publish(const AuditEvent('deleted'));
      }
    }).awaitReady();

    final EventEnvelope<UserEvent>? root = await bus
        .topic(users)
        .publish(const Registered('u-1'));
    final EventEnvelope<AuditEvent> effect = await recorded.future;

    expect(effect.correlationId, root?.id);
    expect(effect.causationId, isNot(root?.id));
    expect(effect.isCaused, isTrue);
    bus.dispose();
  });

  test(
    'a publication outside any consumer starts a chain of its own',
    () async {
      await _withBus((bus) async {
        final EventEnvelope<UserEvent>? first = await bus
            .topic(users)
            .publish(const Registered('u-1'));
        final EventEnvelope<UserEvent>? second = await bus
            .topic(users)
            .publish(const Registered('u-2'));

        expect(second?.correlationId, second?.id);
        expect(second?.correlationId, isNot(first?.correlationId));
      });
    },
  );

  test('naming a cause explicitly wins over the one being handled', () async {
    await _withBus((bus) async {
      final EventEnvelope<UserEvent>? root = await bus
          .topic(users)
          .publish(const Registered('u-1'));
      final EventEnvelope<UserEvent>? other = await bus
          .topic(users)
          .publish(const Registered('u-2'), causedBy: root);

      expect(other?.causationId, root?.id);
      expect(other?.correlationId, root?.correlationId);
    });
  });

  test('a subscriber that throws keeps receiving', () async {
    await _withBus((bus) async {
      final seen = <String>[];
      final failures = <Object>[];
      final EventSubscription subscription = bus.topic(users).subscribe((
        envelope,
      ) {
        final String id = envelope.payload.userId;
        seen.add(id);
        if (id == 'u-1') {
          throw StateError('no');
        }
      }, onError: (error, _) => failures.add(error));
      await subscription.awaitReady();

      await bus.topic(users).publish(const Registered('u-1'));
      await bus.topic(users).publish(const Registered('u-2'));
      await bus.drain();
      await subscription.join();

      expect(seen, <String>['u-1', 'u-2']);
      expect(failures, <Matcher>[
        isA<StateError>().having((error) => error.message, 'message', 'no'),
      ]);
    });
  });

  test('every subscriber sees every envelope', () async {
    await _withBus((bus) async {
      final first = <String>[];
      final second = <String>[];
      final EventSubscription one = bus
          .topic(users)
          .subscribe((envelope) => first.add('${envelope.id}'));
      final EventSubscription other = bus
          .topic(users)
          .subscribe((envelope) => second.add('${envelope.id}'));
      await one.awaitReady();
      await other.awaitReady();

      await bus.topic(users).publish(const Registered('u-1'));
      await bus.drain();
      await one.join();
      await other.join();

      expect(first, second);
      expect(first, hasLength(1));
    });
  });

  test('a subscription is counted while it is attached', () async {
    await _withBus((bus) async {
      final EventTopic<UserEvent> topic = bus.topic(users);
      final EventSubscription subscription = topic.subscribe((_) {});

      expect(topic.subscriberCount, 1);
      expect(subscription.isActive, isTrue);

      await subscription.cancelAndJoin();

      expect(topic.subscriberCount, 0);
      expect(subscription.isActive, isFalse);
    });
  });

  test('a cancelled subscription stops at once', () async {
    await _withBus((bus) async {
      final EventSubscription subscription = bus.topic(users).subscribe((_) {})
        ..cancel();

      expect(subscription.isActive, isFalse);
    });
  });

  test('a subscription is reported under the name it was given', () async {
    await _withBus((bus) async {
      final EventSubscription named = bus
          .topic(users)
          .subscribe((_) {}, name: 'mailer');
      final EventSubscription anonymous = bus.topic(users).subscribe((_) {});

      expect(named.name, 'mailer');
      expect(anonymous.name, startsWith('users#'));
    });
  });

  group('filtering', () {
    test('a predicate decides what reaches the handler', () async {
      await _withBus((bus) async {
        final seen = <String>[];
        final EventSubscription subscription = bus
            .topic(users)
            .subscribeWhere(
              (envelope) => envelope.key == 'keep',
              (envelope) => seen.add(envelope.payload.userId),
            );

        await bus.topic(users).publish(const Registered('u-1'), key: 'keep');
        await bus.topic(users).publish(const Registered('u-2'), key: 'skip');
        await bus.topic(users).publish(const Registered('u-3'), key: 'keep');
        await bus.drain();
        await subscription.join();

        expect(seen, <String>['u-1', 'u-3']);
      });
    });

    test('subscribing to one variant of a hierarchy narrows the '
        'payload', () async {
      await _withBus((bus) async {
        final deleted = <String>[];
        final EventSubscription subscription = bus
            .topic(users)
            .subscribeTo<Deleted>(
              (envelope) => deleted.add(envelope.payload.reason),
            );
        await subscription.awaitReady();

        await bus.topic(users).publish(const Registered('u-1'));
        await bus.topic(users).publish(const Deleted('u-2', 'asked'));
        await bus.drain();
        await subscription.join();

        expect(deleted, <String>['asked']);
      });
    });

    test('a narrowed envelope keeps everything but its type', () async {
      await _withBus((bus) async {
        final narrowed = Completer<EventEnvelope<Deleted>>();
        bus.topic(users).subscribeTo<Deleted>(narrowed.complete);

        final EventEnvelope<UserEvent>? published = await bus
            .topic(users)
            .publish(
              const Deleted('u-1', 'asked'),
              key: 'u-1',
              headers: EventHeaders.of(const <String, String>{
                'tenant': 'acme',
              }),
            );
        final EventEnvelope<Deleted> envelope = await narrowed.future;

        expect(envelope, published);
        expect(envelope.id, published?.id);
        expect(envelope.key, 'u-1');
        expect(envelope.topic, 'users');
        expect(envelope.correlationId, published?.correlationId);
        expect(envelope.headers['tenant'], 'acme');
        expect(envelope.payload, const Deleted('u-1', 'asked'));
      });
    });

    test('a variant the topic does not carry never matches', () async {
      await _withBus((bus) async {
        final audited = <String>[];
        final EventSubscription subscription = bus
            .topic(users)
            .subscribeTo<AuditEvent>(
              (envelope) => audited.add(envelope.payload.action),
            );

        await bus.topic(users).publish(const Registered('u-1'));
        await bus.topic(users).publish(const Deleted('u-2', 'asked'));
        await bus.drain();
        await subscription.join();

        expect(audited, isEmpty);
      });
    });

    test('subscribing once stops after the first match', () async {
      await _withBus((bus) async {
        final seen = <String>[];
        final EventSubscription subscription = bus
            .topic(users)
            .subscribeOnce(
              (envelope) => seen.add(envelope.payload.userId),
              predicate: (envelope) =>
                  envelope.payload == const Registered('u-2'),
            );
        await subscription.awaitReady();

        await bus.topic(users).publish(const Registered('u-1'));
        await bus.topic(users).publish(const Registered('u-2'));
        await bus.topic(users).publish(const Registered('u-3'));
        await subscription.join();

        expect(seen, <String>['u-2']);
        expect(subscription.isActive, isFalse);
      });
    });

    test('subscribing once without a predicate takes the first one', () async {
      await _withBus((bus) async {
        final seen = <String>[];
        final EventSubscription subscription = bus
            .topic(users)
            .subscribeOnce((envelope) => seen.add(envelope.payload.userId));

        await bus.topic(users).publish(const Registered('u-1'));
        await bus.topic(users).publish(const Registered('u-2'));
        await subscription.join();

        expect(seen, <String>['u-1']);
      });
    });
  });

  group('replay', () {
    test('a subscriber attaching late is handed what it missed', () async {
      final EventBus bus = eventBus(
        (it) => it.topic(users, (it) => it.replay = 2),
      );

      await bus.topic(users).publish(const Registered('u-1'));
      await bus.topic(users).publish(const Registered('u-2'));
      await bus.topic(users).publish(const Registered('u-3'));
      await _settle();

      final seen = <String>[];
      final EventSubscription subscription = bus
          .topic(users)
          .subscribe((envelope) => seen.add(envelope.payload.userId));
      await subscription.awaitReady();
      await _settle();
      await bus.drain();
      await subscription.join();

      expect(seen, <String>['u-2', 'u-3']);
    });

    test('a topic that does not replay hands a late subscriber '
        'nothing', () async {
      final EventBus bus = eventBus((it) => it.topic(users));

      await bus.topic(users).publish(const Registered('u-1'));
      await _settle();

      final seen = <String>[];
      final EventSubscription subscription = bus
          .topic(users)
          .subscribe((envelope) => seen.add(envelope.payload.userId));
      await bus.topic(users).publish(const Registered('u-2'));
      await bus.drain();
      await subscription.join();

      expect(seen, <String>['u-2']);
    });

    test('awaiting the next one never answers with something from the '
        'cache', () async {
      final EventBus bus = eventBus(
        (it) => it.topic(users, (it) => it.replay = 5),
      );

      await bus.topic(users).publish(const Registered('old-1'));
      await bus.topic(users).publish(const Registered('old-2'));
      await _settle();

      final Future<EventEnvelope<UserEvent>> awaited = bus.topic(users).next();
      await bus.topic(users).subscribe((_) {}).awaitReady();
      await bus.topic(users).publish(const Registered('new'));

      final EventEnvelope<UserEvent> envelope = await awaited;
      expect(envelope.payload, const Registered('new'));
      bus.dispose();
    });
  });

  group('awaiting the next envelope', () {
    test('sees only what is published after the call', () async {
      await _withBus((bus) async {
        await bus.topic(users).publish(const Registered('before'));
        await _settle();

        final Future<EventEnvelope<UserEvent>> awaited = bus
            .topic(users)
            .next();
        final EventEnvelope<UserEvent>? published = await bus
            .topic(users)
            .publish(const Registered('after'));

        expect(await awaited, published);
      });
    });

    test('skips what does not match the predicate', () async {
      await _withBus((bus) async {
        final Future<EventEnvelope<UserEvent>> awaited = bus
            .topic(users)
            .next((envelope) => envelope.payload is Deleted);

        await bus.topic(users).publish(const Registered('u-1'));
        await bus.topic(users).publish(const Deleted('u-2', 'asked'));

        expect((await awaited).payload, const Deleted('u-2', 'asked'));
      });
    });

    test('fails when the topic is disposed before anything '
        'arrives', () async {
      final EventBus bus = eventBus((it) => it.topic(users));
      final Future<EventEnvelope<UserEvent>> awaited = bus.topic(users).next();

      bus.dispose();

      await expectLater(awaited, throwsStateError);
    });

    test('fails when the topic drains before a match arrives', () async {
      final EventBus bus = eventBus((it) => it.topic(users));
      final Future<EventEnvelope<UserEvent>> awaited = bus
          .topic(users)
          .next((envelope) => envelope.payload is Deleted);
      final Future<void> failed = expectLater(awaited, throwsStateError);

      await bus.topic(users).publish(const Registered('u-1'));
      await bus.drain();

      await failed;
    });

    test('fails at once on a topic that is already closed', () async {
      final EventBus bus = eventBus((it) => it.topic(users))..dispose();

      await expectLater(bus.topic(users).next(), throwsStateError);
    });
  });

  group('as a stream', () {
    test('delivers what is published and closes once the topic '
        'drains', () async {
      final EventBus bus = eventBus((it) => it.topic(users));
      final Future<List<String>> collected = bus
          .topic(users)
          .events()
          .map((envelope) => envelope.payload.userId)
          .toList();

      await bus.topic(users).publish(const Registered('u-1'));
      await bus.topic(users).publish(const Registered('u-2'));
      await bus.drain();

      expect(await collected, <String>['u-1', 'u-2']);
    });

    test('replays to every listener', () async {
      final EventBus bus = eventBus(
        (it) => it.topic(users, (it) => it.replay = 2),
      );

      await bus.topic(users).publish(const Registered('u-1'));
      await bus.topic(users).publish(const Registered('u-2'));
      await bus.topic(users).publish(const Registered('u-3'));
      await _settle();

      final Stream<EventEnvelope<UserEvent>> events = bus.topic(users).events();
      final List<EventEnvelope<UserEvent>> first = await events
          .take(2)
          .toList();
      final List<EventEnvelope<UserEvent>> second = await events
          .take(2)
          .toList();

      expect(first.map((envelope) => envelope.payload.userId), <String>[
        'u-2',
        'u-3',
      ]);
      expect(second, first);
      bus.dispose();
    });

    test('a listener that stops listening is detached', () async {
      await _withBus((bus) async {
        final EventTopic<UserEvent> topic = bus.topic(users);
        final StreamSubscription<EventEnvelope<UserEvent>> listening = topic
            .events()
            .listen((_) {});

        expect(topic.subscriberCount, 1);

        await listening.cancel();
        await _settle();

        expect(topic.subscriberCount, 0);
      });
    });

    test('closes at once on a topic that is already closed', () async {
      final EventBus bus = eventBus((it) => it.topic(users))..dispose();

      expect(await bus.topic(users).events().toList(), isEmpty);
    });
  });

  group('a topic that demands a key', () {
    test('refuses a publication without one', () async {
      final EventBus bus = eventBus((it) {
        it.topic(users, (it) {
          it
            ..partitions = 2
            ..requiresKey = true;
        });
      });

      await expectLater(
        bus.topic(users).publish(const Registered('u-1')),
        throwsArgumentError,
      );
      expect(
        () => bus.topic(users).tryPublish(const Registered('u-1')),
        throwsArgumentError,
      );
      bus.dispose();
    });

    test('accepts a publication with one', () async {
      final EventBus bus = eventBus((it) {
        it.topic(users, (it) {
          it
            ..partitions = 2
            ..requiresKey = true;
        });
      });

      final EventEnvelope<UserEvent>? envelope = await bus
          .topic(users)
          .publish(const Registered('u-1'), key: 'u-1');

      expect(envelope?.key, 'u-1');
      bus.dispose();
    });
  });

  test('two keys naming one topic and disagreeing about it are '
      'refused', () {
    final declared = TopicKey<UserEvent>('users');
    final impostor = TopicKey<AuditEvent>('users');
    final EventBus bus = eventBus((it) => it.topic(declared));

    expect(bus.contains(impostor), isTrue);
    expect(
      () => bus.topic(impostor),
      throwsA(
        isA<TopicTypeMismatchError>()
            .having((failure) => failure.topicName, 'topicName', 'users')
            .having((failure) => failure.declared, 'declared', UserEvent)
            .having((failure) => failure.requested, 'requested', AuditEvent),
      ),
    );
    bus.dispose();
  });

  test('a key resolved against another bus says so', () async {
    final stranger = TopicKey<UserEvent>('elsewhere');
    final EventBus other = eventBus((it) => it.topic(stranger));

    await _withBus((bus) async {
      expect(bus.contains(stranger), isFalse);
      expect(
        () => bus.topic(stranger),
        throwsA(
          isA<TopicNotDeclaredError>()
              .having((failure) => failure.topicName, 'topicName', 'elsewhere')
              .having((failure) => failure.declared, 'declared', <String>{
                'users',
              })
              .having(
                (failure) => '${failure.message}',
                'message',
                contains('elsewhere'),
              ),
        ),
      );
    });
    other.dispose();
  });

  test('the same key resolves the same topic every time', () async {
    await _withBus((bus) async {
      expect(bus.topic(users), same(bus.topic(users)));
      expect(bus.topic(TopicKey<UserEvent>('users')), same(bus.topic(users)));
      expect(bus.topic(users).name, 'users');
      expect(bus.topic(users).eventType, UserEvent);
      expect(bus.topicNames, <String>{'users'});
    });
  });
}
