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

import 'package:essentia_core/essentia_core.dart';

/// Reports that work stopped because its job was cancelled.
///
/// It is not a failure of the work: whoever cancelled the job asked for it.
/// Code that counts failures, retries them or records them leaves a
/// cancellation alone and passes it on, and a coroutine that ends with one
/// is cancelled, not failed.
base class CancellationException implements Exception, Causal {
  /// Creates the exception with an optional [message] saying why the job
  /// was cancelled, and the [cause] behind it.
  const CancellationException([this.message, this.cause]);

  /// Why the job was cancelled, if anybody said.
  final String? message;

  /// The failure that led to the cancellation, if there was one.
  @override
  final Object? cause;

  /// Where [cause] was thrown, which is not recorded: `null`.
  @override
  StackTrace? get causeStackTrace => null;

  /// Renders the exception with its message.
  @override
  String toString() {
    final String? reason = message;
    if (reason == null) {
      return 'CancellationException';
    }
    return 'CancellationException: $reason';
  }
}
