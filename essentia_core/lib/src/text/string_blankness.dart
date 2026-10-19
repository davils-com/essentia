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

/// Checks text for blankness and replaces blank or empty text.
extension StringBlankness on String {
  /// Whether the text is empty or holds only white space.
  bool get isBlank => trim().isEmpty;

  /// Whether the text holds anything besides white space.
  bool get isNotBlank => !isBlank;

  /// The text, or what [fallback] supplies when the text is blank.
  ///
  /// Returns this text, or the result of [fallback] when it is blank.
  @useResult
  String ifBlank(String Function() fallback) => isBlank ? fallback() : this;

  /// The text, or what [fallback] supplies when the text is empty.
  ///
  /// Returns this text, or the result of [fallback] when it is empty.
  @useResult
  String ifEmpty(String Function() fallback) => isEmpty ? fallback() : this;
}
