/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/selects/select_instance.dart';
import 'package:meta/meta.dart';

/// Something a `select` can wait for, which hands a [Q] to the block of the
/// clause that wins.
///
/// Clauses come from the things waited for: `channel.onReceive`,
/// `channel.onReceiveCatching`, `channel.onSend(element)`,
/// `deferred.onAwait` and `job.onJoin`. They are passed to
/// `SelectBuilder.invoke`, or used through the shortcuts of
/// `SelectBuilderClauses` such as `it.onReceive(channel, block)`.
abstract interface class SelectClause<Q> {
  /// Registers the clause with [select]: selects at once when it is ready,
  /// or arranges to select later and hands the select what undoes that.
  @internal
  void register(SelectInstance select);

  /// Turns what the clause selected with into the value its block gets.
  ///
  /// Returns the value.
  ///
  /// Throws the failure the clause selected with, such as the cause of a
  /// closed channel or of a failed deferred.
  @internal
  Q processResult(Object? result);
}
