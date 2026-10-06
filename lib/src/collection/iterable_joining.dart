/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/collection/join_format.dart';
import 'package:meta/meta.dart';

/// Kotlin's `joinToString` for any iterable.
extension IterableJoining<T> on Iterable<T> {
  /// Joins the elements into one string the way [format] describes, each
  /// written with its `toString`.
  ///
  /// Kotlin's `joinToString`: beyond the limit of [format] its `truncated`
  /// marker is written once and the joining stops.
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
