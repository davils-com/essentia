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

import 'package:meta/meta.dart';

/// The failures recorded beside an error, by error.
final _suppressed = Expando<List<Object>>('suppressed exceptions');

/// The failures that were suppressed in favour of [error].
///
/// When several children of a job fail, the job ends with the first
/// failure and records the others beside it.
///
/// Returns the suppressed failures in the order they happened, empty for an
/// error that cannot carry any: a number, a string, a boolean or a record.
List<Object> suppressedExceptionsOf(Object error) {
  if (!_canCarry(error)) {
    return const <Object>[];
  }
  return List<Object>.unmodifiable(_suppressed[error] ?? const <Object>[]);
}

/// Records [suppressed] beside [error], unless it is [error] itself or
/// recorded already.
@internal
void addSuppressed(Object error, Object suppressed) {
  if (identical(error, suppressed) || !_canCarry(error)) {
    return;
  }
  final List<Object> recorded = _suppressed[error] ?? <Object>[];
  if (recorded.any((known) => identical(known, suppressed))) {
    return;
  }
  _suppressed[error] = recorded..add(suppressed);
}

/// Whether an `Expando` can be attached to [error].
///
/// Returns `false` for numbers, strings, booleans and records.
bool _canCarry(Object error) =>
    error is! num && error is! String && error is! bool && error is! Record;
