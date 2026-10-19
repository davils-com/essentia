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

/// How `joinToString` joins elements into one string: its `separator`,
/// `prefix`, `postfix`, `limit` and `truncated` marker.
@immutable
final class JoinFormat {
  /// Creates a format; by default the elements are separated by a comma
  /// and a space, without prefix, postfix or limit, and `...` marks the
  /// truncation.
  ///
  /// Throws an [AssertionError] if [limit] is negative, when assertions
  /// are enabled.
  const JoinFormat({
    this.separator = ', ',
    this.prefix = '',
    this.postfix = '',
    this.limit,
    this.truncated = '...',
  }) : assert(limit == null || limit >= 0, 'A limit must not be negative.');

  /// What is written between two elements.
  final String separator;

  /// What is written before the first element.
  final String prefix;

  /// What is written after the last element.
  final String postfix;

  /// How many elements are written at most, or `null` for all of them.
  final int? limit;

  /// What is written instead of the elements beyond [limit].
  final String truncated;

  /// Whether the element at position [count], counting from one, is still
  /// written.
  ///
  /// Returns `true` without a [limit] or while [count] is within it.
  bool admits(int count) => limit == null || count <= limit!;
}
