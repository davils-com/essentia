/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:meta/meta.dart';

/// Something worth auditing, the second payload type of the event tests.
@immutable
final class AuditEvent implements Event {
  /// Creates the audit record of [action].
  const AuditEvent(this.action);

  /// What was done.
  final String action;

  /// Two records are equal when their actions are.
  @override
  bool operator ==(Object other) =>
      other is AuditEvent && action == other.action;

  /// The hash of the action.
  @override
  int get hashCode => action.hashCode;

  /// Renders the record with its field.
  @override
  String toString() => 'AuditEvent(action=$action)';
}
