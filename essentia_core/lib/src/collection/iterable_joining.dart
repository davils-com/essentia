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

import 'package:essentia_core/src/collection/join_format.dart';
import 'package:meta/meta.dart';

/// Joins the elements of any iterable into one string.
extension IterableJoining<T> on Iterable<T> {
  /// Joins the elements into one string the way [format] describes, each
  /// written with its `toString`.
  ///
  /// Beyond the limit of [format] its `truncated` marker is written once and
  /// the joining stops.
  ///
  /// Returns the joined string, the prefix and postfix only for no
  /// elements.
  @useResult
  String joinToString([JoinFormat format = const JoinFormat()]) {
    final buffer = StringBuffer(format.prefix);
    var count = 0;
    for (final element in this) {
      if (++count > 1) {
        buffer.write(format.separator);
      }
      if (!format.admits(count)) {
        buffer.write(format.truncated);
        break;
      }
      buffer.write(element);
    }
    return (buffer..write(format.postfix)).toString();
  }
}
