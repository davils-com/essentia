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

/// Runs [body] and hands out what it failed with, so that a coroutine that
/// is meant to fail does not fail the test that started it.
///
/// Returns the failure, or `null` when [body] completed.
Future<Object?> failureOf(FutureOr<void> Function() body) async {
  try {
    await body();
    return null;
  } on Object catch (error) {
    return error;
  }
}
