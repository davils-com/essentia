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

import 'package:essentia_core/src/text/linear_reg_exp_failure.dart';

/// A pattern `LinearRegExp` refuses: why, and where in the pattern.
///
/// The message names the reason and the offset, never the pattern, which
/// may come from a document nobody trusts.
final class LinearRegExpException implements Exception {
  /// Refuses a pattern for [failure] at [offset], explained by [detail].
  const LinearRegExpException(this.failure, this.offset, this.detail);

  /// Why the pattern is refused.
  final LinearRegExpFailure failure;

  /// The index of the code unit of the pattern the problem was found at.
  final int offset;

  /// What was wrong there, such as `an unterminated group`.
  final String detail;

  /// The reason, the detail and the offset.
  @override
  String toString() =>
      'LinearRegExpException: ${failure.name} at offset $offset: $detail';
}
