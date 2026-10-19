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

import 'package:essentia_core/essentia_core.dart';
import 'package:meta/meta.dart';

/// A violation written by hand, for the report rendering tests.
@immutable
final class PlainViolation implements Violation {
  /// Creates an error at [path] saying [message].
  PlainViolation.error(String path, this.message)
    : path = _pathOf(path),
      severity = Severity.error,
      code = ViolationCode.invalid;

  /// Creates a warning at [path] saying [message].
  PlainViolation.warning(String path, this.message)
    : path = _pathOf(path),
      severity = Severity.warning,
      code = ViolationCode.invalid;

  /// Where the problem is.
  @override
  final ViolationPath path;

  /// What kind of problem this is.
  @override
  final ViolationCode code;

  /// How badly it matters.
  @override
  final Severity severity;

  /// What is wrong.
  @override
  final String message;

  /// The path named [value], or the root path when [value] is empty.
  static ViolationPath _pathOf(String value) =>
      value.isEmpty ? ViolationPath.root : ViolationPath.of(value);
}
