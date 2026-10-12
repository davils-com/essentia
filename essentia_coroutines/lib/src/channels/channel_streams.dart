/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_coroutines/src/channels/channel_result.dart';
import 'package:essentia_coroutines/src/channels/receive_channel.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_zone.dart';
import 'package:essentia_coroutines/src/coroutine/coroutine_scope_builders.dart';
import 'package:essentia_coroutines/src/coroutine/coroutine_start.dart';
import 'package:essentia_coroutines/src/deferred/completable_deferred.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/job/job.dart';
import 'package:essentia_coroutines/src/scope/context_scope.dart';
import 'package:essentia_coroutines/src/selects/select.dart';
import 'package:essentia_coroutines/src/selects/select_builder_clauses.dart';

/// Kotlin's ways of working through a `ReceiveChannel`: as a stream, the
/// Dart counterpart of a `Flow`, or element by element.
extension ChannelStreams<E> on ReceiveChannel<E> {
  /// The elements of the channel as a stream, Kotlin's `receiveAsFlow()`.
  ///
  /// Every listener receives on its own, so several listeners share the
  /// elements like several receivers do (fan-out); the stream may be
  /// listened to any number of times. Each listener is served by a
  /// coroutine that is a child of the job of the code that listens, and it
  /// receives only while the listener is listening and not paused: an
  /// element is never taken for a listener that cancelled or paused, it
  /// stays in the channel for the next receiver. The stream ends once the
  /// channel is closed, with the close cause as an error if there is one,
  /// and with a `CancellationException` when the listening job is
  /// cancelled.
  ///
  /// Returns the stream.
  Stream<E> receiveAsStream() =>
      Stream<E>.multi((controller) => _pump(controller, consume: false));

  /// The elements of the channel as a stream that may be listened to once
  /// and cancels the channel when it ends, Kotlin's `consumeAsFlow()`.
  ///
  /// It is [receiveAsStream], except that the channel is cancelled once the
  /// stream ends or its listener cancels, and a second listener gets a
  /// [StateError].
  ///
  /// Returns the stream.
  Stream<E> consumeAsStream() {
    var listened = false;
    return Stream<E>.multi((controller) {
      if (listened) {
        controller
          ..addErrorSync(
            StateError('ReceiveChannel.consumeAsStream can be listened once'),
          )
          ..closeSync();
        return;
      }
      listened = true;
      _pump(controller, consume: true);
    });
  }

  /// Runs [action] for every element until the channel is closed, then
  /// cancels it, Kotlin's `consumeEach`.
  ///
  /// Returns a future that completes once the channel is closed and
  /// empty.
  ///
  /// Throws the cause the channel was closed with, what [action] throws -
  /// both cancel the channel - and a [CancellationException] if the
  /// receiver is cancelled.
  Future<void> consumeEach(FutureOr<void> Function(E element) action) =>
      consume((it) async {
        while (true) {
          final ChannelResult<E> result = await it.receiveCatching();
          if (result.isClosed) {
            final Object? cause = result.exceptionOrNull();
            if (cause != null) {
              Error.throwWithStackTrace(cause, StackTrace.current);
            }
            return;
          }
          await action(result.getOrThrow());
        }
      });

  /// Runs [block] with the channel and cancels the channel afterwards,
  /// whatever [block] did, Kotlin's `consume`.
  ///
  /// When [block] fails, the channel is cancelled with a
  /// [CancellationException] caused by the failure.
  ///
  /// Returns what [block] returns.
  ///
  /// Throws what [block] throws.
  Future<R> consume<R>(FutureOr<R> Function(ReceiveChannel<E> it) block) async {
    Object? failure;
    try {
      return await block(this);
    } on Object catch (error) {
      failure = error;
      rethrow;
    } finally {
      _cancelConsumed(failure);
    }
  }

  /// Cancels the channel after it was consumed, with a cancellation caused
  /// by [failure] if the consumer failed, Kotlin's `cancelConsumed`.
  void _cancelConsumed(Object? failure) {
    if (failure == null) {
      cancel();
      return;
    }
    cancel(
      failure is CancellationException
          ? failure
          : CancellationException(
              'Channel was consumed, consumer had failed',
              failure,
            ),
    );
  }

  /// Feeds [controller] from the channel in a coroutine of its own until
  /// the channel is closed or the listener cancels; [consume] cancels the
  /// channel then.
  void _pump(MultiStreamController<E> controller, {required bool consume}) {
    var paused = CompletableDeferred<bool>();
    var resumed = CompletableDeferred<bool>();
    Job? loop;
    controller
      ..onPause = () {
        resumed = CompletableDeferred<bool>();
        paused.complete(true);
      }
      ..onResume = () {
        paused = CompletableDeferred<bool>();
        resumed.complete(true);
      }
      ..onCancel = () {
        loop?.cancel();
        if (consume) {
          cancel();
        }
      };
    loop = ContextScope(currentCoroutineContext())
        .launch(start: CoroutineStart.atomic, (it) async {
          try {
            while (true) {
              it.ensureActive();
              if (controller.isPaused) {
                await resumed;
                continue;
              }
              final ChannelResult<E> taken = tryReceive();
              final ChannelResult<E>? result = taken.isSuccess || taken.isClosed
                  ? taken
                  : await select<ChannelResult<E>?>((it) {
                      it
                        ..onReceiveCatching(this, (result) => result)
                        ..onAwait(paused, (value) => null);
                    });
              if (result == null) {
                continue;
              }
              if (result.isClosed) {
                final Object? cause = result.exceptionOrNull();
                if (cause != null) {
                  controller.addErrorSync(cause);
                }
                controller.closeSync();
                return;
              }
              controller.addSync(result.getOrThrow());
            }
          } on Object catch (error, stackTrace) {
            if (controller.hasListener) {
              controller
                ..addErrorSync(error, stackTrace)
                ..closeSync();
            }
          } finally {
            if (consume) {
              cancel();
            }
          }
        });
  }
}
