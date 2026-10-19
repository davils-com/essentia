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

/// Searches text for several candidates at once, and splits it with a
/// limit.
extension StringSearch on String {
  /// The first index at or after [start] where any of [candidates] occurs.
  ///
  /// Returns the smallest index found, or `-1` when no candidate occurs.
  @useResult
  int indexOfAny(Iterable<String> candidates, [int start = 0]) {
    var found = -1;
    for (final candidate in candidates) {
      final int index = indexOf(candidate, start);
      if (index >= 0 && (found < 0 || index < found)) {
        found = index;
      }
    }
    return found;
  }

  /// The last index at or before [start] where any of [candidates] occurs.
  ///
  /// Without [start] the whole text is searched.
  ///
  /// Returns the largest index found, or `-1` when no candidate occurs.
  @useResult
  int lastIndexOfAny(Iterable<String> candidates, [int? start]) {
    var found = -1;
    for (final candidate in candidates) {
      final int index = lastIndexOf(candidate, start);
      if (index > found) {
        found = index;
      }
    }
    return found;
  }

  /// Splits the text at [delimiter] into at most [limit] parts.
  ///
  /// The last part holds the rest of the text, delimiters included. A
  /// [limit] of `0` splits at every delimiter.
  ///
  /// Returns the parts as an unmodifiable list.
  ///
  /// Throws an [ArgumentError] if [delimiter] is empty, and a [RangeError]
  /// if [limit] is negative.
  @useResult
  List<String> splitWithLimit(String delimiter, int limit) {
    if (delimiter.isEmpty) {
      throw ArgumentError.value(delimiter, 'delimiter', 'must not be empty');
    }
    RangeError.checkNotNegative(limit, 'limit');
    final parts = <String>[];
    var start = 0;
    for (
      int index = indexOf(delimiter);
      index >= 0 && (limit == 0 || parts.length < limit - 1);
      index = indexOf(delimiter, start)
    ) {
      parts.add(substring(start, index));
      start = index + delimiter.length;
    }
    return List<String>.unmodifiable(parts..add(substring(start)));
  }
}
