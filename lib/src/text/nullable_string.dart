/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Kotlin's `isNullOrEmpty`, `isNullOrBlank` and `orEmpty` for text that
/// may be absent.
extension NullableString on String? {
  /// Whether the text is absent or holds no characters at all.
  ///
  /// Kotlin's `CharSequence?.isNullOrEmpty()`.
  bool get isNullOrEmpty => this?.isEmpty ?? true;

  /// Whether the text is absent or holds only white space.
  ///
  /// Kotlin's `CharSequence?.isNullOrBlank()`.
  bool get isNullOrBlank => this?.trim().isEmpty ?? true;

  /// The text, or empty text when it is absent.
  ///
  /// Kotlin's `String?.orEmpty()`.
  ///
  /// Returns this text, or `''` when it is `null`.
  @useResult
  String orEmpty() => this ?? '';
}
