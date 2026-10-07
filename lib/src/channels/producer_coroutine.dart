/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/channels/channel.dart';
import 'package:essentia/src/channels/channel_result.dart';
import 'package:essentia/src/channels/producer_scope.dart';
import 'package:essentia/src/channels/receive_channel.dart';
import 'package:essentia/src/channels/send_channel.dart';
import 'package:essentia/src/coroutines/abstract_coroutine.dart';
import 'package:essentia/src/coroutines/cancellation_exception.dart';
import 'package:essentia/src/coroutines/coroutine_start.dart';
import 'package:essentia/src/coroutines/exception_handling.dart';
import 'package:essentia/src/coroutines/job_cancellation_exception.dart';
import 'package:essentia/src/selects/select_clause.dart';
import 'package:meta/meta.dart';

/// The coroutine of `produce`, Kotlin's `ProducerCoroutine`: the scope of
/// the producer and the channel handed to the consumer in one.
///
/// It closes the channel once it completes, with its failure as the cause
/// when it fails; cancelling the channel cancels the coroutine.
@internal
final class ProducerCoroutine<E> extends AbstractCoroutine<void>
    implements ProducerScope<E>, ReceiveChannel<E> {
  /// Creates the coroutine with [parentContext], sending to [_channel].
  ProducerCoroutine(super.parentContext, this._channel) : super(active: true);

  /// The channel the coroutine sends to.
  final Channel<E> _channel;

  /// Whether the failure of the coroutine was left to it because no parent
  /// took it over.
  var _unhandled = false;

  /// Names the kind of coroutine.
  @override
  String get kind => 'ProducerCoroutine';

  /// See [ProducerScope.channel].
  @override
  SendChannel<E> get channel => this;

  /// See [SendChannel.isClosedForSend].
  @override
  bool get isClosedForSend => _channel.isClosedForSend;

  /// See [ReceiveChannel.isClosedForReceive].
  @override
  bool get isClosedForReceive => _channel.isClosedForReceive;

  /// See [ReceiveChannel.isEmpty].
  @override
  bool get isEmpty => _channel.isEmpty;

  /// See [ReceiveChannel.onReceive].
  @override
  SelectClause<E> get onReceive => _channel.onReceive;

  /// See [ReceiveChannel.onReceiveCatching].
  @override
  SelectClause<ChannelResult<E>> get onReceiveCatching =>
      _channel.onReceiveCatching;

  /// Starts [block] the way [start] says, with this coroutine as its scope.
  void startProducer(
    CoroutineStart start,
    FutureOr<void> Function(ProducerScope<E> it) block,
  ) => startCoroutine(start, (it) => block(this));

  /// See [ProducerScope.send].
  @override
  Future<void> send(E element) => _channel.send(element);

  /// See [SendChannel.trySend].
  @override
  ChannelResult<void> trySend(E element) => _channel.trySend(element);

  /// See [SendChannel.close].
  @override
  bool close([Object? cause]) => _channel.close(cause);

  /// See [SendChannel.invokeOnClose].
  @override
  void invokeOnClose(void Function(Object? cause) handler) =>
      _channel.invokeOnClose(handler);

  /// See [SendChannel.onSend].
  @override
  SelectClause<SendChannel<E>> onSend(E element) => _channel.onSend(element);

  /// See [ReceiveChannel.receive].
  @override
  Future<E> receive() => _channel.receive();

  /// See [ReceiveChannel.receiveCatching].
  @override
  Future<ChannelResult<E>> receiveCatching() => _channel.receiveCatching();

  /// See [ReceiveChannel.tryReceive].
  @override
  ChannelResult<E> tryReceive() => _channel.tryReceive();

  /// Cancels the channel, dropping what it holds, and the coroutine,
  /// Kotlin's `ChannelCoroutine.cancel`.
  @override
  void cancel([CancellationException? cause]) {
    final CancellationException reason =
        cause ?? JobCancellationException('Job was cancelled', job: this);
    _channel.cancel(reason);
    cancelImpl(reason, StackTrace.current);
  }

  /// Notes that no parent took the failure over.
  ///
  /// Returns `true`; whether it is reported is decided once the channel is
  /// closed.
  @override
  bool handleJobException(Object error, StackTrace stackTrace) {
    _unhandled = true;
    return true;
  }

  /// Closes the channel, with the failure or cancellation of the coroutine
  /// as the cause; a failure that neither the channel nor a parent took is
  /// reported to the context.
  @override
  void onCompletionInternal(AsyncError? error) {
    if (error == null) {
      _channel.close();
      return;
    }
    final bool closed = _channel.close(error.error);
    if (!closed && _unhandled) {
      handleCoroutineException(
        coroutineContext,
        error.error,
        error.stackTrace,
        zone: zone,
      );
    }
  }
}
