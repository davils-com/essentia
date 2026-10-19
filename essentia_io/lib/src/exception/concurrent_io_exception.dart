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

/// Thrown when two coroutines read, or two write, a byte channel at the
/// same time.
///
/// A channel has one reader and one writer; a second one at the same time
/// is a programming mistake, so this is an [Error].
final class ConcurrentIoException extends StateError {
  /// Creates the error for a concurrent [task], `read` or `write`.
  ConcurrentIoException(this.task) : super('Concurrent $task attempts');

  /// What was attempted twice at the same time: `read` or `write`.
  final String task;
}
