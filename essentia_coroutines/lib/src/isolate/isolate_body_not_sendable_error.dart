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
import 'package:meta/meta.dart';

/// A body handed to `Dispatchers.isolate` could not cross the border
/// between isolates: the body itself, something it captures, or its result
/// cannot be sent through a `SendPort`.
///
/// It is a programming mistake, so it is an `Error`. Write the body as a
/// closure that captures only sendable values, and return a sendable
/// result; the restrictions are those of `SendPort.send`.
final class IsolateBodyNotSendableError extends ArgumentError
    implements Causal {
  /// Creates the error of a body that could not be sent because of
  /// [cause].
  @internal
  IsolateBodyNotSendableError.body(this.cause) : inResult = false;

  /// Creates the error of a body whose result could not be sent back.
  @internal
  IsolateBodyNotSendableError.result() : inResult = true, cause = null;

  /// Whether the result was not sendable, rather than the body.
  final bool inResult;

  /// What `SendPort.send` threw for the body, if it was the body.
  @override
  final Object? cause;

  /// Where [cause] was thrown, which is not recorded: `null`.
  @override
  StackTrace? get causeStackTrace => null;

  /// Renders the error without quoting a value of the body.
  @override
  String toString() {
    if (inResult) {
      return 'IsolateBodyNotSendableError: The result of a body run on '
          'Dispatchers.isolate cannot be sent back; return a value '
          'SendPort.send accepts';
    }
    return 'IsolateBodyNotSendableError: A body run on Dispatchers.isolate '
        'cannot be sent to a worker isolate; the body and everything it '
        'captures must be sendable, see SendPort.send';
  }
}
