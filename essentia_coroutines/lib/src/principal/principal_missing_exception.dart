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

/// Thrown by `requirePrincipal()` when the current zone holds no principal.
///
/// Nothing about permission: code that requires a caller and finds none was
/// reached without the edge that establishes one having run. That is a
/// defect in how the call was set up, and treating it as "access denied"
/// would hide it.
final class PrincipalMissingException implements Exception {
  /// Creates the exception.
  @internal
  const PrincipalMissingException();

  /// What went wrong and how to fix it.
  String get message =>
      'No principal in the current zone. Establish one at the edge that '
      'verified the caller, with runAsPrincipal(principal(...), body), '
      'before calling code that requires it.';

  /// The [message].
  @override
  String toString() => 'PrincipalMissingException: $message';
}
