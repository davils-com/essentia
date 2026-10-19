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

/// Where a bus or one of its topics is in its life.
///
/// One value rather than a pair of booleans, because shutting down and
/// having shut down are different states and code that tracked them
/// separately could be in neither or in both.
///
/// The order is the only order these occur in. Nothing goes back.
enum BusState {
  /// Accepting publications and delivering them.
  running,

  /// No longer accepting publications, still delivering what it already
  /// holds.
  ///
  /// Entered only by an orderly shutdown. An abrupt one goes straight to
  /// [closed].
  draining,

  /// Finished. Every subscription is cancelled and every publication is
  /// refused.
  closed,
}
