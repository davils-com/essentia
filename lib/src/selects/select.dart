/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/coroutines/cancellation_exception.dart';
import 'package:essentia/src/selects/select_builder.dart';
import 'package:essentia/src/selects/select_implementation.dart';

/// Waits for the first of several clauses, Kotlin's `select`.
///
/// [block] registers the clauses with the builder it gets. They register
/// in that order, and the select is biased like Kotlin's: when several are
/// ready at once, the first one wins. Exactly one clause wins; its block
/// runs in the caller's context and its result is the result of the
/// select. A losing clause takes nothing: an element stays in its channel.
///
/// ```dart
/// final String text = await select<String>((it) {
///   it.onReceive(fizz, (value) => 'fizz -> $value');
///   it.onReceive(buzz, (value) => 'buzz -> $value');
///   it.onTimeout(const Duration(seconds: 1), () => 'nothing');
/// });
/// ```
///
/// Waiting is cancellable: a cancelled caller disposes every clause.
///
/// Returns the result of the block of the winning clause.
///
/// Throws the failure of the winning clause - a receive on a closed
/// channel, a failed deferred - or of its block, and a
/// [CancellationException] if the caller is cancelled while it waits.
Future<R> select<R>(void Function(SelectBuilder<R> it) block) =>
    SelectImplementation<R>().run(block, unbiased: false);

/// Waits for the first of several clauses without preferring any, Kotlin's
/// `selectUnbiased`.
///
/// It is [select], except that the clauses register in a random order, so
/// when several are ready at once each one wins as often as the others.
///
/// Returns the result of the block of the winning clause.
///
/// Throws what [select] throws.
Future<R> selectUnbiased<R>(void Function(SelectBuilder<R> it) block) =>
    SelectImplementation<R>().run(block, unbiased: true);
