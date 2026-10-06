/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
import 'package:test/test.dart';

/// Runs [action], which is expected to fail because of what was passed.
///
/// Returns the [ParameterException] it threw.
///
/// Throws a [StateError] if [action] completed normally.
ParameterException failureOf(void Function() action) {
  try {
    action();
  } on ParameterException catch (failure) {
    return failure;
  }
  throw StateError('Expected a ParameterException, but loading succeeded');
}

/// Runs the asynchronous [action], which is expected to fail because of
/// what was passed.
///
/// Returns the [ParameterException] it completed with.
///
/// Throws a [StateError] if [action] completed normally.
Future<ParameterException> failureOfAsync(
  Future<void> Function() action,
) async {
  try {
    await action();
  } on ParameterException catch (failure) {
    return failure;
  }
  throw StateError('Expected a ParameterException, but loading succeeded');
}

/// Expects [failure] to carry exactly one violation, of type [V].
///
/// Returns that violation.
V singleViolation<V extends ParameterViolation>(ParameterException failure) {
  expect(failure.violations, <Matcher>[isA<V>()]);
  return failure.violations.whereType<V>().single;
}
