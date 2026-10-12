/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:meta/meta.dart';

/// Adds the value that [produce] returns to [sink], or the error it throws
/// as an error event, so that a failing callback of an operator never
/// escapes as an uncaught error.
///
/// Returns `true` when a value was added, `false` when an error was.
@internal
bool emitCatching<T>(EventSink<T> sink, T Function() produce) {
  final T value;
  try {
    value = produce();
  } on Object catch (error, stackTrace) {
    sink.addError(error, stackTrace);
    return false;
  }
  sink.add(value);
  return true;
}

/// Runs [action] and adds the error it throws to [sink] as an error event.
///
/// Returns `true` when [action] completed, `false` when it threw.
@internal
bool runCatchingInto<T>(EventSink<T> sink, void Function() action) {
  try {
    action();
  } on Object catch (error, stackTrace) {
    sink.addError(error, stackTrace);
    return false;
  }
  return true;
}
