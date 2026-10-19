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

/// Reports that the test body of `runTest`, or a coroutine it waits for, did
/// not complete in time.
final class UncompletedCoroutinesError extends AssertionError {
  /// Creates the error with [message].
  UncompletedCoroutinesError(String super.message);

  /// Renders the error with its message.
  @override
  String toString() => 'UncompletedCoroutinesError: $message';
}
