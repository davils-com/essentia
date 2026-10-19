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

/// Something whose release has to wait for work in flight.
///
/// This is `Disposable` for the case where letting go is not instantaneous:
/// a queue that should be drained, a connection that should be told it is
/// going away, a worker that should finish the item it is holding. A type
/// that can do both offers `Disposable.dispose` for the abrupt path and
/// this one for the orderly path, and says which is which.
///
/// [dispose] is idempotent. A second call completes once the first has
/// settled rather than starting the teardown again.
abstract interface class DisposableAsync {
  /// Releases what this object holds, completing when that is done.
  ///
  /// The object is unusable afterwards. How long this takes is the
  /// implementation's to document, and where it waits on somebody else's
  /// code it says so.
  Future<void> dispose();
}
