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

/// A hot stream whose values are shared between all of its listeners.
///
/// A shared flow never ends: a listener stays subscribed until it cancels
/// or the job it listened in is cancelled. A new listener gets the
/// [replayCache] first and then every value emitted after it subscribed.
///
/// A listener that listens inside a coroutine is ended when the job of
/// that coroutine is cancelled: it gets the `CancellationException` of
/// the job as an error event, and then the stream is done for it. So
/// `await for` over a shared flow inside a coroutine, and `collect`,
/// end with that exception instead of keeping the cancelled job waiting
/// forever. A plain `listen` without `onError` inside a coroutine sees
/// that exception as an uncaught error; prefer `collect` and `launchIn`.
///
/// A listener that pauses - `await for` does while its body runs - holds
/// its place in the shared buffer, so a slow listener slows the emitters
/// down instead of losing values.
///
/// It is a broadcast stream: [isBroadcast] is `true`.
abstract interface class SharedFlow<T> implements Stream<T> {
  /// The values a new listener gets first, oldest first.
  ///
  /// The list is a snapshot and cannot be changed.
  List<T> get replayCache;
}
