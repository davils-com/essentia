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
import 'package:essentia_core/src/result/result_dsl.dart';

/// Captures the outcome of a future as a [Result].
extension ResultFuture<T> on Future<T> {
  /// Awaits this future and captures its outcome.
  ///
  /// Returns a [Success] carrying the value this future completes with, or a
  /// [Failure] carrying its error and stack trace.
  Future<Result<T>> toResult() => runCatchingAsync<T>(() => this);
}
