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

import 'package:meta/meta.dart';

/// Splits an iterable of pairs into two lists.
extension RecordIterableUnzip<A, B> on Iterable<(A, B)> {
  /// Splits the pairs into their first and their second parts.
  ///
  /// Returns both parts as unmodifiable lists in the order of the pairs.
  @useResult
  (List<A>, List<B>) unzip() {
    final firsts = <A>[];
    final seconds = <B>[];
    for (final (first, second) in this) {
      firsts.add(first);
      seconds.add(second);
    }
    return (List<A>.unmodifiable(firsts), List<B>.unmodifiable(seconds));
  }
}
