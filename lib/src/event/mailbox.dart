/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';
import 'dart:collection';

import 'package:essentia/src/event/mailbox_offer.dart';
import 'package:meta/meta.dart';

/// A bounded queue of [T] between tasks of one isolate, the counterpart of
/// a Kotlin channel.
///
/// A sender that finds the mailbox full waits until a receiver makes room,
/// and a receiver that finds it empty waits until a sender delivers. A
/// mailbox of capacity zero is a rendezvous: a send completes only once a
/// receiver took the element.
///
/// [close] stops new sends and still hands out everything buffered or
/// waiting; [cancel] drops all of it.
@internal
final class Mailbox<T extends Object> {
  /// Creates a mailbox holding up to [capacity] elements.
  Mailbox(this.capacity);

  /// How many elements the mailbox holds before a sender has to wait.
  final int capacity;

  /// The elements taken in and not yet handed out, oldest first.
  final _buffer = Queue<T>();

  /// The senders waiting for room, with their elements, oldest first.
  final _senders = Queue<(T, Completer<bool>)>();

  /// The receivers waiting for an element, oldest first.
  final _receivers = Queue<Completer<T?>>();

  /// Whether the mailbox refuses new sends.
  var _closed = false;

  /// How many elements are waiting to be received, buffered or held by a
  /// waiting sender.
  int get length => _buffer.length + _senders.length;

  /// Whether the mailbox refuses new sends.
  bool get isClosed => _closed;

  /// Sends [element], waiting for room if there is none.
  ///
  /// Returns `true` once the mailbox took the element, `false` if it was
  /// closed before or cancelled while waiting.
  Future<bool> send(T element) {
    if (_closed) {
      return Future<bool>.value(false);
    }
    if (_takeWithoutWaiting(element)) {
      return Future<bool>.value(true);
    }
    final completer = Completer<bool>();
    _senders.add((element, completer));
    return completer.future;
  }

  /// Sends [element] only if that needs no waiting.
  ///
  /// Returns whether the element was accepted, or why not.
  MailboxOffer trySend(T element) {
    if (_closed) {
      return MailboxOffer.closed;
    }
    if (_takeWithoutWaiting(element)) {
      return MailboxOffer.accepted;
    }
    return MailboxOffer.full;
  }

  /// Receives the oldest element, waiting for one if there is none.
  ///
  /// Returns the element, or `null` once the mailbox is closed and empty.
  Future<T?> receive() {
    final T? element = tryReceive();
    if (element != null || _closed) {
      return Future<T?>.value(element);
    }
    final completer = Completer<T?>();
    _receivers.add(completer);
    return completer.future;
  }

  /// Receives the oldest element if there is one.
  ///
  /// Returns the element, or `null` if nothing is waiting.
  T? tryReceive() {
    if (_buffer.isNotEmpty) {
      final T element = _buffer.removeFirst();
      _admitWaitingSender();
      return element;
    }
    if (_senders.isEmpty) {
      return null;
    }
    final (T element, Completer<bool> sent) = _senders.removeFirst();
    sent.complete(true);
    return element;
  }

  /// Refuses new sends while still handing out what is buffered or held by
  /// a waiting sender.
  void close() {
    _closed = true;
    if (length > 0) {
      return;
    }
    _releaseReceivers();
  }

  /// Refuses new sends and drops everything, so that waiting senders learn
  /// they were not taken and waiting receivers that nothing is coming.
  void cancel() {
    _closed = true;
    _buffer.clear();
    while (_senders.isNotEmpty) {
      _senders.removeFirst().$2.complete(false);
    }
    _releaseReceivers();
  }

  /// Hands [element] to a waiting receiver or buffers it.
  ///
  /// Returns `true` when one of the two took it.
  bool _takeWithoutWaiting(T element) {
    if (_receivers.isNotEmpty) {
      _receivers.removeFirst().complete(element);
      return true;
    }
    if (_buffer.length < capacity) {
      _buffer.add(element);
      return true;
    }
    return false;
  }

  /// Moves the element of the oldest waiting sender into the room that was
  /// just made.
  void _admitWaitingSender() {
    if (_senders.isEmpty) {
      return;
    }
    final (T element, Completer<bool> sent) = _senders.removeFirst();
    _buffer.add(element);
    sent.complete(true);
  }

  /// Tells every waiting receiver that nothing is coming.
  void _releaseReceivers() {
    while (_receivers.isNotEmpty) {
      _receivers.removeFirst().complete(null);
    }
  }
}
