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

/// What a channel does with an element sent while its buffer is full.
enum BufferOverflow {
  /// The sender waits until there is room.
  suspend,

  /// The oldest buffered element is dropped to make room; the sender never
  /// waits.
  dropOldest,

  /// The element being sent is dropped; the sender never waits.
  dropLatest,
}
