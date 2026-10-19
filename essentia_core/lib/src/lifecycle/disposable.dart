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

/// Something that holds resources until it is told to let go of them.
///
/// A disposed object is finished for good rather than merely closed for
/// this block.
///
/// [dispose] is idempotent. Calling it a second time does nothing and does
/// not fail, so a shutdown path that cannot know whether it already ran
/// does not have to guess.
abstract interface class Disposable {
  /// Releases what this object holds.
  ///
  /// The object is unusable afterwards. Implementations decide what an
  /// operation on a disposed object does, but they say so, and they never
  /// make a second [dispose] an error.
  void dispose();
}
