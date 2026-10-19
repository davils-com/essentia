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
