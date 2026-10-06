/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/event/mailbox.dart';
import 'package:essentia/src/event/mailbox_offer.dart';
import 'package:test/test.dart';

/// Checks the bounded queue every topic, subscriber and group is built on.
void main() {
  group('sending and receiving', () {
    test('hands elements out in the order they were sent', () async {
      final mailbox = Mailbox<String>(3);

      expect(await mailbox.send('a'), isTrue);
      expect(await mailbox.send('b'), isTrue);
      expect(await mailbox.send('c'), isTrue);

      expect(await mailbox.receive(), 'a');
      expect(await mailbox.receive(), 'b');
      expect(await mailbox.receive(), 'c');
    });

    test('hands a waiting receiver the next element sent', () async {
      final mailbox = Mailbox<String>(2);
      final Future<String?> receiving = mailbox.receive();

      expect(await mailbox.send('a'), isTrue);

      expect(await receiving, 'a');
      expect(mailbox.length, 0);
    });

    test('serves waiting receivers oldest first', () async {
      final mailbox = Mailbox<String>(0);
      final Future<String?> first = mailbox.receive();
      final Future<String?> second = mailbox.receive();

      expect(mailbox.trySend('a'), MailboxOffer.accepted);
      expect(mailbox.trySend('b'), MailboxOffer.accepted);

      expect(await first, 'a');
      expect(await second, 'b');
    });

    test('answers nothing when asked without waiting while empty', () {
      final mailbox = Mailbox<String>(2);

      expect(mailbox.tryReceive(), isNull);
    });
  });

  group('a mailbox of capacity zero', () {
    test('completes a send only once a receiver took the element', () async {
      final mailbox = Mailbox<String>(0);
      var sent = false;
      final Future<void> sending = mailbox.send('a').then((accepted) {
        sent = accepted;
      });
      await pumpEventQueue();

      expect(sent, isFalse);
      expect(mailbox.length, 1);

      expect(await mailbox.receive(), 'a');
      await sending;

      expect(sent, isTrue);
      expect(mailbox.length, 0);
    });

    test('refuses an offer nobody is waiting for', () {
      final mailbox = Mailbox<String>(0);

      expect(mailbox.trySend('a'), MailboxOffer.full);
      expect(mailbox.length, 0);
    });
  });

  group('a full mailbox', () {
    test('admits a waiting sender once a receiver makes room', () async {
      final mailbox = Mailbox<String>(1);
      expect(await mailbox.send('a'), isTrue);
      var admitted = false;
      final Future<void> waiting = mailbox.send('b').then((accepted) {
        admitted = accepted;
      });
      await pumpEventQueue();

      expect(admitted, isFalse);
      expect(mailbox.length, 2);

      expect(mailbox.tryReceive(), 'a');
      await waiting;

      expect(admitted, isTrue);
      expect(mailbox.length, 1);
      expect(await mailbox.receive(), 'b');
    });

    test('admits waiting senders in the order they started waiting', () async {
      final mailbox = Mailbox<String>(1);
      expect(await mailbox.send('a'), isTrue);
      final Future<bool> second = mailbox.send('b');
      final Future<bool> third = mailbox.send('c');

      final received = <String?>[
        await mailbox.receive(),
        await mailbox.receive(),
        await mailbox.receive(),
      ];

      expect(received, <String>['a', 'b', 'c']);
      expect(await second, isTrue);
      expect(await third, isTrue);
    });

    test('refuses an offer that would have to wait', () async {
      final mailbox = Mailbox<String>(1);

      expect(mailbox.trySend('a'), MailboxOffer.accepted);
      expect(mailbox.trySend('b'), MailboxOffer.full);

      expect(mailbox.length, 1);
      expect(await mailbox.receive(), 'a');
    });
  });

  group('counting', () {
    test('counts what is buffered and what waiting senders hold', () {
      final mailbox = Mailbox<String>(2);

      expect(mailbox.length, 0);
      unawaited(mailbox.send('a'));
      unawaited(mailbox.send('b'));
      unawaited(mailbox.send('c'));

      expect(mailbox.length, 3);

      mailbox.cancel();
    });

    test('counts nothing a waiting receiver took straight away', () {
      final mailbox = Mailbox<String>(2);
      unawaited(mailbox.receive());

      expect(mailbox.trySend('a'), MailboxOffer.accepted);

      expect(mailbox.length, 0);
    });
  });

  group('closing', () {
    test('refuses new sends', () async {
      final mailbox = Mailbox<String>(2)..close();

      expect(mailbox.isClosed, isTrue);
      expect(await mailbox.send('a'), isFalse);
      expect(mailbox.trySend('b'), MailboxOffer.closed);
      expect(mailbox.length, 0);
    });

    test('still hands out what is buffered and what senders hold', () async {
      final mailbox = Mailbox<String>(1);
      expect(await mailbox.send('a'), isTrue);
      final Future<bool> waiting = mailbox.send('b');

      mailbox.close();

      expect(mailbox.length, 2);
      expect(await mailbox.receive(), 'a');
      expect(await mailbox.receive(), 'b');
      expect(await waiting, isTrue);
      expect(await mailbox.receive(), isNull);
    });

    test('tells waiting receivers that nothing is coming', () async {
      final mailbox = Mailbox<String>(1);
      final Future<String?> first = mailbox.receive();
      final Future<String?> second = mailbox.receive();

      mailbox.close();

      expect(await first, isNull);
      expect(await second, isNull);
    });

    test('answers a receiver straight away once empty', () async {
      final mailbox = Mailbox<String>(1)..close();

      expect(await mailbox.receive(), isNull);
      expect(mailbox.tryReceive(), isNull);
    });
  });

  group('cancelling', () {
    test('tells waiting senders they were not taken', () async {
      final mailbox = Mailbox<String>(1);
      expect(await mailbox.send('a'), isTrue);
      final Future<bool> second = mailbox.send('b');
      final Future<bool> third = mailbox.send('c');

      mailbox.cancel();

      expect(await second, isFalse);
      expect(await third, isFalse);
    });

    test('drops what is buffered', () async {
      final mailbox = Mailbox<String>(2);
      expect(await mailbox.send('a'), isTrue);
      expect(await mailbox.send('b'), isTrue);

      mailbox.cancel();

      expect(mailbox.isClosed, isTrue);
      expect(mailbox.length, 0);
      expect(mailbox.tryReceive(), isNull);
      expect(await mailbox.receive(), isNull);
    });

    test('tells waiting receivers that nothing is coming', () async {
      final mailbox = Mailbox<String>(0);
      final Future<String?> receiving = mailbox.receive();

      mailbox.cancel();

      expect(await receiving, isNull);
    });

    test('refuses new sends', () async {
      final mailbox = Mailbox<String>(2)..cancel();

      expect(await mailbox.send('a'), isFalse);
      expect(mailbox.trySend('b'), MailboxOffer.closed);
    });
  });
}
