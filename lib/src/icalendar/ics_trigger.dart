/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/time/date_time_period.dart';
import 'package:essentia/src/time/instant.dart';
import 'package:meta/meta.dart';

/// When an alarm goes off, the `TRIGGER` of RFC 5545: an
/// [IcsRelativeTrigger] before or after the start or end of its entry, or
/// an [IcsAbsoluteTrigger] at a moment.
@immutable
sealed class IcsTrigger {
  /// Creates the trigger.
  const IcsTrigger();
}

/// An alarm [offset] from the start of its entry, or from the end when
/// [fromEnd]; negative before.
final class IcsRelativeTrigger extends IcsTrigger {
  /// The alarm [offset] from the start, or from the end when [fromEnd].
  const IcsRelativeTrigger(this.offset, {this.fromEnd = false});

  /// How far from the start or end, negative before.
  final DateTimePeriod offset;

  /// Whether [offset] counts from the end.
  final bool fromEnd;

  /// Whether [other] is the same trigger.
  @override
  bool operator ==(Object other) =>
      other is IcsRelativeTrigger &&
      other.offset == offset &&
      other.fromEnd == fromEnd;

  /// A hash of the trigger.
  @override
  int get hashCode => Object.hash(offset, fromEnd);

  /// Describes the trigger.
  @override
  String toString() => 'IcsRelativeTrigger($offset${fromEnd ? ', end' : ''})';
}

/// An alarm at [instant].
final class IcsAbsoluteTrigger extends IcsTrigger {
  /// The alarm at [instant].
  const IcsAbsoluteTrigger(this.instant);

  /// The moment of the alarm.
  final Instant instant;

  /// Whether [other] goes off at the same moment.
  @override
  bool operator ==(Object other) =>
      other is IcsAbsoluteTrigger && other.instant == instant;

  /// A hash of the moment.
  @override
  int get hashCode => instant.hashCode;

  /// Describes the trigger.
  @override
  String toString() => 'IcsAbsoluteTrigger($instant)';
}
