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

import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:meta/meta.dart';

/// Reports that `withTimeout` ran out of time.
///
/// Inside the timed out block it is the cancellation of its job; thrown out
/// of `withTimeout` it tells the caller that the limit passed.
final class TimeoutCancellationException extends CancellationException {
  /// Creates the exception with [message], raised by [coroutine].
  const TimeoutCancellationException(String super.message, {this.coroutine});

  /// The coroutine whose time ran out, which tells `withTimeoutOrNull` its
  /// own timeout apart from an inner one.
  @internal
  final Object? coroutine;

  /// Renders the exception with its message.
  @override
  String toString() => 'TimeoutCancellationException: $message';
}
