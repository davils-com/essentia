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

/// What a windowing operation does with the elements at the end that do
/// not fill a whole window.
enum WindowRemainder {
  /// The last, partial windows are left out, so every window has the full
  /// size. This is the default.
  drop,

  /// The last, partial windows are kept, each smaller than the one before.
  keep;

  /// Whether windows smaller than the requested size are kept.
  bool get keepsPartialWindows => this == keep;
}
