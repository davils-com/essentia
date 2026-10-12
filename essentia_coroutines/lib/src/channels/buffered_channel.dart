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

import 'package:essentia_coroutines/src/channels/buffer_overflow.dart';
import 'package:essentia_coroutines/src/channels/channel.dart';
import 'package:essentia_coroutines/src/channels/channel_closed.dart';
import 'package:essentia_coroutines/src/channels/channel_result.dart';
import 'package:essentia_coroutines/src/channels/closed_receive_channel_exception.dart';
import 'package:essentia_coroutines/src/channels/closed_send_channel_exception.dart';
import 'package:essentia_coroutines/src/channels/continuation_receive_waiter.dart';
import 'package:essentia_coroutines/src/channels/continuation_send_waiter.dart';
import 'package:essentia_coroutines/src/channels/receive_catching_clause.dart';
import 'package:essentia_coroutines/src/channels/receive_channel.dart';
import 'package:essentia_coroutines/src/channels/receive_clause.dart';
import 'package:essentia_coroutines/src/channels/receive_waiter.dart';
import 'package:essentia_coroutines/src/channels/select_receive_waiter.dart';
import 'package:essentia_coroutines/src/channels/select_send_waiter.dart';
import 'package:essentia_coroutines/src/channels/send_channel.dart';
import 'package:essentia_coroutines/src/channels/send_clause.dart';
import 'package:essentia_coroutines/src/channels/send_waiter.dart';
import 'package:essentia_coroutines/src/continuation/suspension.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/job/disposable_action.dart';
import 'package:essentia_coroutines/src/selects/select_clause.dart';
import 'package:essentia_coroutines/src/selects/select_instance.dart';
import 'package:meta/meta.dart';

/// The channel behind `Channel()`, Kotlin's `BufferedChannel` and
/// `ConflatedBufferedChannel` in one.
///
/// An isolate runs one thing at a time, so the channel is a plain buffer
/// and two queues of waiters instead of Kotlin's lock-free segments. A
/// waiter is always resumed before the element offered to it moves: a
/// waiter that cannot take part any more - a select that chose another
/// clause - leaves the element where it is. A select never pairs its own
/// sender with its own receiver.
@internal
final class BufferedChannel<E> implements Channel<E> {
  /// Creates a channel the way `Channel()` documents it, resolving
  /// [capacity] and [onBufferOverflow] like Kotlin's `Channel()` factory.
  ///
  /// Throws an [ArgumentError] if [capacity] is negative and no constant
  /// of `Channel`, or if a conflated channel is given an overflow policy.
  factory BufferedChannel({
    int capacity = Channel.rendezvous,
    BufferOverflow onBufferOverflow = BufferOverflow.suspend,
    void Function(E element)? onUndeliveredElement,
  }) {
    final void Function(Object? element)? undelivered =
        onUndeliveredElement == null
        ? null
        : (element) => onUndeliveredElement(element as E);
    final suspending = onBufferOverflow == BufferOverflow.suspend;
    if (capacity == Channel.conflated) {
      if (!suspending) {
        throw ArgumentError.value(
          onBufferOverflow,
          'onBufferOverflow',
          'A conflated channel takes no other overflow policy than suspend',
        );
      }
      return BufferedChannel<E>._(1, BufferOverflow.dropOldest, undelivered);
    }
    if (capacity == Channel.unlimited) {
      return BufferedChannel<E>._(
        Channel.unlimited,
        BufferOverflow.suspend,
        undelivered,
      );
    }
    if (capacity == Channel.rendezvous || capacity == Channel.buffered) {
      if (!suspending) {
        return BufferedChannel<E>._(1, onBufferOverflow, undelivered);
      }
      return BufferedChannel<E>._(
        capacity == Channel.buffered ? Channel.defaultCapacity : 0,
        onBufferOverflow,
        undelivered,
      );
    }
    if (capacity < 0) {
      throw ArgumentError.value(
        capacity,
        'capacity',
        'Invalid channel capacity, should be at least zero',
      );
    }
    return BufferedChannel<E>._(capacity, onBufferOverflow, undelivered);
  }

  /// Creates a channel buffering [_capacity] elements and applying
  /// [_overflow] beyond, reporting dropped elements to [_onUndelivered].
  BufferedChannel._(this._capacity, this._overflow, this._onUndelivered);

  /// How many elements the buffer holds.
  final int _capacity;

  /// What a send to a full buffer does.
  final BufferOverflow _overflow;

  /// Takes every element that is never received.
  final void Function(Object? element)? _onUndelivered;

  /// The elements sent and not yet received, oldest first.
  final _buffer = ListQueue<E>();

  /// The senders waiting for room, oldest first.
  final _senders = LinkedList<SendWaiter<E>>();

  /// The receivers waiting for an element, oldest first.
  final _receivers = LinkedList<ReceiveWaiter<E>>();

  /// Whether the channel was closed or cancelled.
  var _closed = false;

  /// What the channel was closed with, `null` for a normal close.
  Object? _closeCause;

  /// The handler of [invokeOnClose] until it ran.
  void Function(Object? cause)? _closeHandler;

  /// Whether [invokeOnClose] was called.
  var _closeHandlerRegistered = false;

  /// How many elements wait to be received: the buffered ones and those of
  /// waiting senders.
  int get size => _buffer.length + _senders.length;

  /// See [SendChannel.isClosedForSend].
  @override
  bool get isClosedForSend => _closed;

  /// See [ReceiveChannel.isClosedForReceive].
  @override
  bool get isClosedForReceive => _closed && _buffer.isEmpty && _senders.isEmpty;

  /// See [ReceiveChannel.isEmpty].
  @override
  bool get isEmpty => !_closed && _buffer.isEmpty && _senders.isEmpty;

  /// See [ReceiveChannel.onReceive].
  @override
  SelectClause<E> get onReceive => ReceiveClause<E>(this);

  /// See [ReceiveChannel.onReceiveCatching].
  @override
  SelectClause<ChannelResult<E>> get onReceiveCatching =>
      ReceiveCatchingClause<E>(this);

  /// See [SendChannel.onSend].
  @override
  SelectClause<SendChannel<E>> onSend(E element) =>
      SendClause<E>(this, element);

  /// See [Channel.send].
  @override
  Future<void> send(E element) {
    if (_closed) {
      _undeliver(element);
      return Future<void>.error(sendException(), StackTrace.current);
    }
    if (_offer(element, sending: true)) {
      return Future<void>.value();
    }
    return suspendCancellableCoroutine<void>((it) {
      final waiter = ContinuationSendWaiter<E>(element, it);
      _senders.add(waiter);
      it.invokeOnCancellation((cause) {
        if (waiter.list != null) {
          waiter.unlink();
          _undeliver(element);
        }
      });
    });
  }

  /// See [SendChannel.trySend].
  @override
  ChannelResult<void> trySend(E element) {
    if (_closed) {
      return ChannelClosed<void>(sendException());
    }
    if (_offer(element, sending: false)) {
      return const ChannelSuccess<void>(null);
    }
    return const ChannelFailure<void>();
  }

  /// See [ReceiveChannel.receive].
  @override
  Future<E> receive() => receiveCatching().then(valueOrThrow);

  /// See [ReceiveChannel.receiveCatching].
  @override
  Future<ChannelResult<E>> receiveCatching() {
    final ChannelResult<E>? taken = _take();
    if (taken != null) {
      return Future<ChannelResult<E>>.value(taken);
    }
    return suspendCancellableCoroutine<ChannelResult<E>>((it) {
      final waiter = ContinuationReceiveWaiter<E>(this, it);
      _receivers.add(waiter);
      it.invokeOnCancellation((cause) => _unlink(waiter));
    });
  }

  /// See [ReceiveChannel.tryReceive].
  @override
  ChannelResult<E> tryReceive() => _take() ?? ChannelFailure<E>();

  /// See [Channel.close].
  @override
  bool close([Object? cause]) {
    if (_closed) {
      return false;
    }
    _closed = true;
    _closeCause = cause;
    _releaseReceiversIfDrained();
    _invokeCloseHandler();
    return true;
  }

  /// See [Channel.cancel].
  @override
  void cancel([CancellationException? cause]) {
    final bool closing = !_closed;
    if (closing) {
      _closed = true;
      _closeCause =
          cause ?? const CancellationException('Channel was cancelled');
    }
    final dropped = List<E>.of(_buffer);
    _buffer.clear();
    final Object failure = sendException();
    while (_senders.isNotEmpty) {
      final SendWaiter<E> sender = _senders.first..unlink();
      if (sender.fail(failure)) {
        dropped.add(sender.element);
      }
    }
    _releaseReceivers();
    if (closing) {
      _invokeCloseHandler();
    }
    _undeliverAll(dropped);
  }

  /// See [SendChannel.invokeOnClose].
  @override
  void invokeOnClose(void Function(Object? cause) handler) {
    if (_closeHandlerRegistered) {
      throw StateError('Another close handler was registered already');
    }
    _closeHandlerRegistered = true;
    if (_closed) {
      handler(_closeCause);
      return;
    }
    _closeHandler = handler;
  }

  /// Registers the receive clause of [select]: it is selected at once with
  /// an element or the closure of the channel, or waits for either.
  void registerReceive(SelectInstance select) {
    final ChannelResult<E>? taken = _take(
      owner: select.owner,
      claim: select.trySelect,
    );
    if (taken != null) {
      return;
    }
    final waiter = SelectReceiveWaiter<E>(this, select);
    _receivers.add(waiter);
    select.disposeOnCompletion(DisposableAction(() => _unlink(waiter)));
  }

  /// Registers the send clause of [select] sending [element]: it is
  /// selected at once when the channel takes the element or is closed, or
  /// waits for room.
  void registerSend(SelectInstance select, E element) {
    if (_closed) {
      if (select.trySelect(ChannelClosed<void>(sendException()))) {
        _undeliver(element);
      }
      return;
    }
    final bool taken = _offer(
      element,
      sending: false,
      owner: select.owner,
      claim: () => select.trySelect(const ChannelSuccess<void>(null)),
    );
    if (taken) {
      return;
    }
    final waiter = SelectSendWaiter<E>(element, select);
    _senders.add(waiter);
    select.disposeOnCompletion(DisposableAction(() => _unlink(waiter)));
  }

  /// What a send to the closed channel throws: the close cause, or a
  /// [ClosedSendChannelException].
  ///
  /// Returns the failure.
  Object sendException() => _closeCause ?? ClosedSendChannelException();

  /// The element of [result], for a receive.
  ///
  /// Returns the element.
  ///
  /// Throws the close cause, or a [ClosedReceiveChannelException], if
  /// [result] is a [ChannelClosed].
  E valueOrThrow(ChannelResult<E> result) {
    if (result is ChannelClosed<E>) {
      Error.throwWithStackTrace(
        result.cause ?? ClosedReceiveChannelException(),
        StackTrace.current,
      );
    }
    return result.getOrThrow();
  }

  /// Hands the element of [result], if it carries one, to
  /// `onUndeliveredElement`, because its receiver was cancelled before it
  /// took it.
  void undeliverResult(ChannelResult<E> result) {
    if (result is ChannelSuccess<E>) {
      _undeliver(result.value);
    }
  }

  /// Hands [element] to a waiting receiver, buffers it, or applies the
  /// overflow policy; [claim] wins the select of [owner] right before the
  /// element moves.
  ///
  /// [sending] says whether a `send` offers it, which is the only one that
  /// reports an element dropped by [BufferOverflow.dropLatest], as in
  /// Kotlin.
  ///
  /// Returns `false` when the sender has to wait for room.
  bool _offer(
    E element, {
    required bool sending,
    Object? owner,
    void Function()? claim,
  }) {
    for (
      ReceiveWaiter<E>? receiver = _firstReceiver(owner);
      receiver != null;
      receiver = _firstReceiver(owner)
    ) {
      receiver.unlink();
      if (receiver.resume(ChannelSuccess<E>(element))) {
        claim?.call();
        return true;
      }
    }
    if (_buffer.length < _capacity) {
      claim?.call();
      _buffer.add(element);
      return true;
    }
    switch (_overflow) {
      case BufferOverflow.suspend:
        return false;
      case BufferOverflow.dropOldest:
        claim?.call();
        final E evicted = _buffer.removeFirst();
        _buffer.add(element);
        _undeliver(evicted);
        return true;
      case BufferOverflow.dropLatest:
        claim?.call();
        if (sending) {
          _undeliver(element);
        }
        return true;
    }
  }

  /// Takes the next element for a receiver of [owner]: the oldest buffered
  /// one, or the one of the oldest waiting sender; [claim] wins the select
  /// of [owner] right before the element moves.
  ///
  /// Returns the element taken, a [ChannelClosed] once the channel is
  /// closed for receive, or `null` when the receiver has to wait.
  ChannelResult<E>? _take({
    Object? owner,
    void Function(ChannelResult<E> result)? claim,
  }) {
    if (_buffer.isNotEmpty) {
      final result = ChannelSuccess<E>(_buffer.first);
      claim?.call(result);
      _buffer.removeFirst();
      _admitSenders();
      _releaseReceiversIfDrained();
      return result;
    }
    for (
      SendWaiter<E>? sender = _firstSender(owner);
      sender != null;
      sender = _firstSender(owner)
    ) {
      sender.unlink();
      if (sender.resume()) {
        final result = ChannelSuccess<E>(sender.element);
        claim?.call(result);
        _releaseReceiversIfDrained();
        return result;
      }
    }
    if (isClosedForReceive) {
      final result = ChannelClosed<E>(_closeCause);
      claim?.call(result);
      return result;
    }
    return null;
  }

  /// Moves the elements of waiting senders into the room of the buffer.
  void _admitSenders() {
    while (_buffer.length < _capacity && _senders.isNotEmpty) {
      final SendWaiter<E> sender = _senders.first..unlink();
      if (sender.resume()) {
        _buffer.add(sender.element);
      }
    }
  }

  /// The oldest waiting receiver that does not belong to [owner].
  ///
  /// Returns the receiver, or `null` when there is none.
  ReceiveWaiter<E>? _firstReceiver(Object? owner) {
    ReceiveWaiter<E>? candidate = _receivers.isEmpty ? null : _receivers.first;
    while (candidate != null &&
        owner != null &&
        identical(candidate.owner, owner)) {
      candidate = candidate.next;
    }
    return candidate;
  }

  /// The oldest waiting sender that does not belong to [owner].
  ///
  /// Returns the sender, or `null` when there is none.
  SendWaiter<E>? _firstSender(Object? owner) {
    SendWaiter<E>? candidate = _senders.isEmpty ? null : _senders.first;
    while (candidate != null &&
        owner != null &&
        identical(candidate.owner, owner)) {
      candidate = candidate.next;
    }
    return candidate;
  }

  /// Tells the waiting receivers that the channel is closed once it holds
  /// nothing more.
  void _releaseReceiversIfDrained() {
    if (isClosedForReceive) {
      _releaseReceivers();
    }
  }

  /// Tells every waiting receiver that the channel is closed.
  void _releaseReceivers() {
    while (_receivers.isNotEmpty) {
      _receivers.first
        ..unlink()
        ..resume(ChannelClosed<E>(_closeCause));
    }
  }

  /// Runs the handler of [invokeOnClose], once.
  void _invokeCloseHandler() {
    final void Function(Object? cause)? handler = _closeHandler;
    _closeHandler = null;
    handler?.call(_closeCause);
  }

  /// Hands [element] to `onUndeliveredElement`.
  void _undeliver(E element) => _onUndelivered?.call(element);

  /// Hands every one of [elements] to `onUndeliveredElement`, even when an
  /// earlier one fails.
  ///
  /// Throws the first failure of `onUndeliveredElement` once all elements
  /// were handed over.
  void _undeliverAll(List<E> elements) {
    AsyncError? failure;
    for (final element in elements) {
      try {
        _undeliver(element);
      } on Object catch (error, stackTrace) {
        failure ??= AsyncError(error, stackTrace);
      }
    }
    if (failure != null) {
      Error.throwWithStackTrace(failure.error, failure.stackTrace);
    }
  }

  /// Takes [waiter] out of its queue, unless it is out already.
  static void _unlink<W extends LinkedListEntry<W>>(W waiter) {
    if (waiter.list != null) {
      waiter.unlink();
    }
  }
}
