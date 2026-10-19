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
import 'dart:math';

import 'package:essentia_coroutines/src/continuation/cancellable_continuation.dart';
import 'package:essentia_coroutines/src/continuation/suspension.dart';
import 'package:essentia_coroutines/src/selects/clause_registration.dart';
import 'package:essentia_coroutines/src/selects/select_builder.dart';
import 'package:essentia_coroutines/src/selects/select_clause.dart';
import 'package:essentia_coroutines/src/selects/timeout_clause.dart';
import 'package:meta/meta.dart';

/// The state machine of `select`.
///
/// An isolate runs one thing at a time, so a single flag decides the winner
/// instead of an atomic state: the first clause that selects wins, every other
/// registration is disposed at once, and the block of the winner runs in the
/// caller's context.
@internal
final class SelectImplementation<R> implements SelectBuilder<R> {
  /// The clauses, in the order they were registered with the builder.
  final _registrations = <ClauseRegistration<R>>[];

  /// The clause that won, `null` until one did.
  ClauseRegistration<R>? _winner;

  /// The continuation of the waiting caller, `null` while the clauses
  /// register.
  CancellableContinuation<ClauseRegistration<R>>? _continuation;

  /// Whether a clause won or the caller was cancelled.
  var _over = false;

  /// Whether a clause won or the caller was cancelled.
  bool get isOver => _over;

  /// See [SelectBuilder.invoke].
  @override
  void invoke<Q>(SelectClause<Q> clause, FutureOr<R> Function(Q value) block) {
    _registrations.add(
      ClauseRegistration<R>(
        this,
        clause.register,
        (result) => block(clause.processResult(result)),
      ),
    );
  }

  /// See [SelectBuilder.onTimeout].
  @override
  void onTimeout(Duration timeout, FutureOr<R> Function() block) =>
      invoke<void>(TimeoutClause(timeout), (value) => block());

  /// Builds the select with [block], registers its clauses - in a random
  /// order when [unbiased] - and waits for the first one to win.
  ///
  /// The block of the winner runs in the same microtask in which the
  /// caller's cancellation was checked a last time, so an element handed
  /// over never sits in between.
  ///
  /// Returns the result of the block of the winning clause.
  ///
  /// Throws the failure the winner selected with, what its block throws,
  /// and a `CancellationException` if the caller is cancelled while it
  /// waits.
  Future<R> run(
    void Function(SelectBuilder<R> it) block, {
    required bool unbiased,
  }) {
    try {
      block(this);
      final List<ClauseRegistration<R>> order = unbiased
          ? (List<ClauseRegistration<R>>.of(_registrations)..shuffle(_random))
          : _registrations;
      for (final registration in order) {
        if (_over) {
          break;
        }
        registration.register();
      }
    } on Object catch (error, stackTrace) {
      _end();
      return Future<R>.error(error, stackTrace);
    }
    final ClauseRegistration<R>? winner = _winner;
    if (winner != null) {
      return Future<R>.sync(winner.complete);
    }
    return suspendCancellableCoroutine<ClauseRegistration<R>>((it) {
      _continuation = it;
      it.invokeOnCancellation((cause) => _end());
    }).then((registration) => registration.complete());
  }

  /// Makes [registration] the winner and disposes every registration; the
  /// waiting caller goes on, and [onCancellation] runs if it is cancelled
  /// before it does.
  void selected(
    ClauseRegistration<R> registration,
    void Function()? onCancellation,
  ) {
    _winner = registration;
    _end();
    _continuation?.resume(
      registration,
      onCancellation: onCancellation == null
          ? null
          : (cause, value) => onCancellation(),
    );
  }

  /// Ends the select and disposes every registration.
  void _end() {
    _over = true;
    for (final ClauseRegistration<R> registration in _registrations) {
      registration.dispose();
    }
  }

  /// Shuffles the clauses of an unbiased select.
  static final _random = Random();
}
