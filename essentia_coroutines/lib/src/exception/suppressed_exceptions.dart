/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
