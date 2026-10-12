/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:test/test.dart';

import '../support/audit_event.dart';
import '../support/topics.dart';
import '../support/user_event.dart';

/// A placeholder standing in for a sensitive attribute.
const _placeholder = 'placeholder-value';

/// A user holding the role `reader`.
final Principal _alice = principal(
  'alice',
  (it) => it.roles(const <String>['reader']),
);

/// A service consuming on its own behalf.
final _indexer = Principal.of('indexer', kind: PrincipalKind.service);

/// Tests who an envelope records as its publisher, and who its consumers run
/// as.
void main() {
  group('publishing', () {
    test('records the principal of the publishing zone', () async {
      final EventBus bus = eventBus((it) => it.topic(users));

      final EventEnvelope<UserEvent>? envelope = await runAsPrincipal(
        _alice,
        () => bus.topic(users).publish(const Registered('u-1')),
      );

      expect(envelope?.principal, _alice);
      bus.dispose();
    });

    test('records none when the publishing zone has none', () async {
      final EventBus bus = eventBus((it) => it.topic(users));

      final EventEnvelope<UserEvent>? envelope = await bus
          .topic(users)
          .publish(const Registered('u-1'));

      expect(envelope, isNotNull);
      expect(envelope?.principal, isNull);
      bus.dispose();
    });

    test('records an explicitly named principal instead of the '
        "zone's", () async {
      final EventBus bus = eventBus((it) => it.topic(users));

      final EventEnvelope<UserEvent>? envelope = await runAsPrincipal(
        _alice,
        () => bus.topic(users).publishAs(_indexer, const Registered('u-1')),
      );

      expect(envelope?.principal, _indexer);
      bus.dispose();
    });

    test('records none when explicitly told so, even inside a zone that has '
        'one', () async {
      final EventBus bus = eventBus((it) => it.topic(users));

      final EventEnvelope<UserEvent>? envelope = await runAsPrincipal(
        _alice,
        () => bus.topic(users).publishAs(null, const Registered('u-1')),
      );

      expect(envelope, isNotNull);
      expect(envelope?.principal, isNull);
      bus.dispose();
    });

    test('a publish that will not wait reads the zone as well, where Arc '
        'records only what it is told', () {
      final EventBus bus = eventBus((it) => it.topic(users));

      final EventEnvelope<UserEvent>? fromZone = runAsPrincipal(
        _alice,
        () => bus.topic(users).tryPublish(const Registered('u-1')),
      );
      final EventEnvelope<UserEvent>? named = bus
          .topic(users)
          .tryPublishAs(_alice, const Registered('u-2'));
      final EventEnvelope<UserEvent>? none = runAsPrincipal(
        _alice,
        () => bus.topic(users).tryPublishAs(null, const Registered('u-3')),
      );

      expect(fromZone?.principal, _alice);
      expect(named?.principal, _alice);
      expect(none, isNotNull);
      expect(none?.principal, isNull);
      bus.dispose();
    });
  });

  group('consuming', () {
    test("a subscriber handles the envelope inside the publisher's "
        'principal', () async {
      final seen = <String?>[];
      final EventBus bus = eventBus((it) => it.topic(users));
      final EventSubscription subscription = bus
          .topic(users)
          .subscribe((_) => seen.add(currentPrincipal()?.id));
      await subscription.awaitReady();

      await runAsPrincipal(
        _alice,
        () => bus.topic(users).publish(const Registered('u-1')),
      );
      await bus.drain();
      await subscription.join();

      expect(seen, <String?>['alice']);
    });

    test('a consumer group worker does too', () async {
      final seen = <String?>[];
      final EventBus bus = eventBus((it) => it.topic(users));
      bus
          .topic(users)
          .group('indexer', (_) => seen.add(currentPrincipal()?.id));

      await runAsPrincipal(
        _alice,
        () => bus.topic(users).publish(const Registered('u-1')),
      );
      await bus.drain();

      expect(seen, <String?>['alice']);
    });

    test('an interceptor sees it on the envelope and in its zone', () async {
      final seen = <String>[];
      final EventBus bus = eventBus((it) {
        it
          ..intercept((envelope, _, proceed) async {
            seen.add(
              'envelope=${envelope.principal?.id} '
              'zone=${currentPrincipal()?.id}',
            );
            await proceed();
          })
          ..topic(users);
      });
      final EventSubscription subscription = bus.topic(users).subscribe((_) {});
      await subscription.awaitReady();

      await runAsPrincipal(
        _alice,
        () => bus.topic(users).publish(const Registered('u-1')),
      );
      await bus.drain();
      await subscription.join();

      expect(seen, <String>['envelope=alice zone=alice']);
    });

    test("an envelope without one leaves the consumer's own principal in "
        'place', () async {
      final seen = <String?>[];
      final EventBus bus = eventBus((it) => it.topic(users));
      final EventSubscription subscription = runAsPrincipal(
        _indexer,
        () =>
            bus.topic(users).subscribe((_) => seen.add(currentPrincipal()?.id)),
      );
      await subscription.awaitReady();

      await bus.topic(users).publish(const Registered('u-1'));
      await pumpEventQueue();

      expect(seen, <String?>['indexer']);
      bus.dispose();
    });

    test('what a consumer publishes carries the principal on, with the '
        'chain', () async {
      final EventBus bus = eventBus((it) {
        it
          ..topic(users)
          ..topic(audit);
      });
      final audited = <EventEnvelope<AuditEvent>>[];
      final EventSubscription auditing = bus
          .topic(audit)
          .subscribe(audited.add);
      await auditing.awaitReady();
      final EventSubscription registering = bus
          .topic(users)
          .subscribe(
            (_) => bus.topic(audit).publish(const AuditEvent('registered')),
          );
      await registering.awaitReady();

      final EventEnvelope<UserEvent>? cause = await runAsPrincipal(
        _alice,
        () => bus.topic(users).publish(const Registered('u-1')),
      );
      await bus.drain();
      await auditing.join();

      final EventEnvelope<AuditEvent> consequence = audited.single;
      expect(consequence.principal, _alice);
      expect(cause, isNotNull);
      expect(consequence.causationId, cause?.id);
    });
  });

  group('rendering', () {
    test('names the publisher by id and never prints its attributes', () async {
      final EventBus bus = eventBus((it) => it.topic(users));
      final Principal caller = principal(
        'alice',
        (it) => it.attribute('email', _placeholder, sensitive: true),
      );

      final EventEnvelope<UserEvent>? envelope = await runAsPrincipal(
        caller,
        () => bus.topic(users).publish(const Registered('u-1')),
      );
      final rendered = envelope.toString();

      expect(rendered, contains('publishedBy=alice'));
      expect(rendered, isNot(contains(_placeholder)));
      expect(rendered, isNot(contains('email')));
      bus.dispose();
    });
  });
}
