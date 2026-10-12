/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/channels/channel_closed.dart';
import 'package:essentia_coroutines/src/channels/channel_result.dart';
import 'package:essentia_coroutines/src/channels/send_waiter.dart';
import 'package:essentia_coroutines/src/selects/select_instance.dart';
import 'package:meta/meta.dart';

/// The waiter of an `onSend` clause, which resumes by selecting the clause.
@internal
final class SelectSendWaiter<E> extends SendWaiter<E> {
  /// Creates the waiter of the `onSend` clause of [_select] sending
  /// [element].
  SelectSendWaiter(super.element, this._select);

  /// The select the clause belongs to.
  final SelectInstance _select;

  /// See [SendWaiter.owner].
  @override
  Object? get owner => _select.owner;

  /// See [SendWaiter.resume].
  @override
  bool resume() => _select.trySelect(const ChannelSuccess<void>(null));

  /// See [SendWaiter.fail].
  @override
  bool fail(Object error) => _select.trySelect(ChannelClosed<void>(error));
}
