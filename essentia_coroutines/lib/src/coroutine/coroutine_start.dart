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

/// How a coroutine builder starts its coroutine.
enum CoroutineStart {
  /// Dispatches the body right away; a coroutine cancelled before its body ran
  /// never runs it. The name avoids `default`, a reserved word in Dart.
  defaultStart,

  /// Starts the coroutine only when it is started, joined or awaited.
  lazy,

  /// Dispatches the body right away, and runs it even if the coroutine is
  /// cancelled before it ran.
  atomic,

  /// Runs the body at once, in the caller's frame, up to its first
  /// suspension.
  undispatched,
}
