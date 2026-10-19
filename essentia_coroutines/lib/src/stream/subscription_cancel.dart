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

import 'dart:async';

import 'package:meta/meta.dart';

/// The future `StreamSubscription.cancel` returns when there was nothing
/// to clean up.
///
/// It is one completed future of the root zone, so code that awaits it
/// goes on in a microtask of the root zone, past the virtual event loop of
/// a `TestScheduler`; inside `runTest` that code would run late, on the
/// real event loop.
final Future<void> _idleCancel = const Stream<Never>.empty()
    .listen(null)
    .cancel();

/// Keeps the future that `StreamSubscription.cancel` returned,
/// [cancelling], in the current zone.
///
/// Returns [cancelling], or a completed future of the current zone when it
/// is the shared future of a cancel that had nothing to clean up.
@internal
Future<void> keepInZone(Future<void> cancelling) {
  if (identical(cancelling, _idleCancel)) {
    return Future<void>.value();
  }
  return cancelling;
}

/// Runs [then] once the cancel that returned [cancelling] cleaned up,
/// whether the cleanup succeeded or failed; a failed cleanup is dropped,
/// as the stream it belongs to is left behind anyway.
@internal
void afterCancel(Future<void> cancelling, void Function() then) {
  unawaited(
    keepInZone(cancelling)
        .then((_) => then(), onError: (Object error) => then()),
  );
}
