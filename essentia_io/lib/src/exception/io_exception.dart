/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:meta/meta.dart';

/// A failure of input or output, kotlinx-io's `IOException`: a channel
/// that was closed or cancelled, data that ended too soon, a line that is
/// too long.
///
/// It is named `IoException`, not `IOException`, so that it does not clash
/// with the class of `dart:io` in a file that imports both.
base class IoException implements Exception, Causal {
  /// Creates the exception with [message] and the [cause] behind it.
  const IoException(this.message, {this.cause, this.causeStackTrace});

  /// What went wrong.
  final String message;

  /// The failure behind this one, if there is one.
  @override
  final Object? cause;

  /// Where [cause] was thrown, where it is known.
  @override
  final StackTrace? causeStackTrace;

  /// The name of the exception in [toString], which every subtype names
  /// itself by.
  @protected
  String get kind => 'IoException';

  /// Describes the exception by its [kind] and [message].
  ///
  /// Returns the description.
  @override
  String toString() => '$kind: $message';
}
