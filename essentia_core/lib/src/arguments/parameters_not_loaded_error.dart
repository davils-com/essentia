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

/// Thrown when a schema is read before it was loaded.
///
/// This is a defect in the program's startup order, not a problem with what
/// the user passed, and it is deliberately an error rather than a
/// `ParameterException` so that the two can never be confused for one
/// another: an unloaded schema and a genuinely missing value must not look
/// alike, or startup bugs look like user error.
final class ParametersNotLoadedError extends StateError {
  /// Creates the error for [subject], which was read too early.
  @internal
  ParametersNotLoadedError(String subject)
    : super('$subject was accessed before load() was called on its schema');
}
