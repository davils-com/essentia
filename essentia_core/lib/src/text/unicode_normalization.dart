/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/text/internal/unicode_normalizer.dart';
import 'package:meta/meta.dart';

/// The Unicode canonical normalization forms of UAX #15 on text: NFC, the
/// composed form, and NFD, the decomposed form.
///
/// Java's and Kotlin's `Normalizer.normalize` with `Normalizer.Form.NFC` and
/// `Normalizer.Form.NFD`, and JavaScript's `String.prototype.normalize`, on
/// the character data of Unicode 16.0.0 and the same on every platform.
/// They work on code points, so a surrogate pair is one character; a lone
/// surrogate is kept as it is.
extension UnicodeNormalization on String {
  /// The text in the Normalization Form C: canonically decomposed,
  /// reordered and composed again, so `'ü'` becomes `'ü'`.
  ///
  /// Kotlin's `Normalizer.normalize(text, Normalizer.Form.NFC)`.
  ///
  /// Returns this very text when it already is in NFC.
  @useResult
  String toNfc() => normalizeNfc(this);

  /// The text in the Normalization Form D: canonically decomposed and
  /// reordered, so `'ü'` becomes `'ü'`.
  ///
  /// Kotlin's `Normalizer.normalize(text, Normalizer.Form.NFD)`.
  ///
  /// Returns this very text when it already is in NFD.
  @useResult
  String toNfd() => normalizeNfd(this);

  /// Whether the text is in the Normalization Form C, so [toNfc] leaves it
  /// as it is.
  ///
  /// Kotlin's `Normalizer.isNormalized(text, Normalizer.Form.NFC)`.
  bool get isNfc => isNormalizedNfc(this);
}
