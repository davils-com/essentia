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

/// Waits for a future for a limited time.
extension FutureTimeout<T> on Future<T> {
  /// Waits at most [limit] for this future.
  ///
  /// The work behind the future is not cancelled when the limit passes; it runs
  /// to its end and its result is dropped.
  ///
  /// Returns the value of this future, or `null` when [limit] passes first.
  ///
  /// Throws the error of this future if it fails within [limit].
  Future<T?> timeoutOrNull(Duration limit) =>
      then<T?>((value) => value).timeout(limit, onTimeout: () => null);
}
