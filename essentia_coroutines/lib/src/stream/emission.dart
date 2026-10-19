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
