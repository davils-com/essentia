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

/// What a `SharingStarted` strategy tells the coroutine that shares a
/// stream.
enum SharingCommand {
  /// Starts listening to the upstream stream; nothing happens if it is
  /// listened to already.
  start,

  /// Stops listening to the upstream stream.
  stop,

  /// Stops listening to the upstream stream and forgets the replay values,
  /// or resets a state flow to its initial value.
  stopAndResetReplayCache,
}
