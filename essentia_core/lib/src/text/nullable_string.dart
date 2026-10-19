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

/// Asks whether text that may be absent is empty or blank, and replaces
/// absent text with empty text.
extension NullableString on String? {
  /// Whether the text is absent or holds no characters at all.
  bool get isNullOrEmpty => this?.isEmpty ?? true;

  /// Whether the text is absent or holds only white space.
  bool get isNullOrBlank => this?.trim().isEmpty ?? true;

  /// The text, or empty text when it is absent.
  ///
  /// Returns this text, or `''` when it is `null`.
  @useResult
  String orEmpty() => this ?? '';
}
