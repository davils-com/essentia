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

import 'package:essentia_core/src/text/internal/unicode_normalizer.dart';
import 'package:meta/meta.dart';

/// The Unicode canonical normalization forms of UAX #15 on text: NFC, the
/// composed form, and NFD, the decomposed form.
///
/// They follow the character data of Unicode 16.0.0 and give the same result on
/// every platform. They work on code points, so a surrogate pair is one
/// character; a lone surrogate is kept as it is.
extension UnicodeNormalization on String {
  /// The text in the Normalization Form C: canonically decomposed,
  /// reordered and composed again, so `'ü'` becomes `'ü'`.
  ///
  /// Returns this very text when it already is in NFC.
  @useResult
  String toNfc() => normalizeNfc(this);

  /// The text in the Normalization Form D: canonically decomposed and
  /// reordered, so `'ü'` becomes `'ü'`.
  ///
  /// Returns this very text when it already is in NFD.
  @useResult
  String toNfd() => normalizeNfd(this);

  /// Whether the text is in the Normalization Form C, so [toNfc] leaves it
  /// as it is.
  bool get isNfc => isNormalizedNfc(this);
}
