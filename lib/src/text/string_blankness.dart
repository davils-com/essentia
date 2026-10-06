/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Kotlin's `isBlank`, `isNotBlank`, `ifBlank` and `ifEmpty` for text.
extension StringBlankness on String {
  /// Whether the text is empty or holds only white space.
  ///
  /// Kotlin's `CharSequence.isBlank()`.
  bool get isBlank => trim().isEmpty;

  /// Whether the text holds anything besides white space.
  ///
  /// Kotlin's `CharSequence.isNotBlank()`.
  bool get isNotBlank => !isBlank;

  /// The text, or what [fallback] supplies when the text is blank.
  ///
  /// Kotlin's `CharSequence.ifBlank`.
  ///
  /// Returns this text, or the result of [fallback] when it is blank.
  @useResult
  String ifBlank(String Function() fallback) => isBlank ? fallback() : this;

  /// The text, or what [fallback] supplies when the text is empty.
  ///
  /// Kotlin's `CharSequence.ifEmpty`.
  ///
  /// Returns this text, or the result of [fallback] when it is empty.
  @useResult
  String ifEmpty(String Function() fallback) => isEmpty ? fallback() : this;
}
