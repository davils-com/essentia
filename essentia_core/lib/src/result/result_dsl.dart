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

import 'package:essentia_core/src/result/result.dart';

/// Runs [block] and captures its outcome.
///
/// Everything [block] throws is caught, errors included.
///
/// Returns a [Success] carrying what [block] returns, or a [Failure]
/// carrying what it threw and the stack trace it was thrown with.
Result<T> runCatching<T>(T Function() block) {
  try {
    return Success<T>(block());
  } on Object catch (error, stackTrace) {
    return Failure<T>(error, stackTrace);
  }
}

/// Awaits [block] and captures its outcome, the [runCatching] of an
/// asynchronous block.
///
/// Everything [block] throws or completes with as an error is caught.
///
/// Returns a [Success] carrying what [block] completes with, or a [Failure]
/// carrying the error and its stack trace.
Future<Result<T>> runCatchingAsync<T>(Future<T> Function() block) async {
  try {
    return Success<T>(await block());
  } on Object catch (error, stackTrace) {
    return Failure<T>(error, stackTrace);
  }
}
