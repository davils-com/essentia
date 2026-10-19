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

import 'package:essentia_core/src/bytes/hex_format.dart';
import 'package:essentia_core/src/dsl/builder.dart';

/// The builder behind `hexFormat`.
final class HexFormatBuilder implements Builder<HexFormat> {
  /// Whether the digits `a` to `f` are written in upper case.
  var upperCase = false;

  /// What is written between two bytes.
  var byteSeparator = '';

  /// What is written before the two digits of every byte.
  var bytePrefix = '';

  /// What is written after the two digits of every byte.
  var byteSuffix = '';

  /// Produces the format.
  ///
  /// Returns the format.
  @override
  HexFormat build() => HexFormat(
    upperCase: upperCase,
    byteSeparator: byteSeparator,
    bytePrefix: bytePrefix,
    byteSuffix: byteSuffix,
  );
}
