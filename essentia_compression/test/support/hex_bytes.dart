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

import 'dart:typed_data';

/// The bytes a string of hexadecimal digits spells, for test vectors.
extension HexBytes on String {
  /// The bytes of this string, two hexadecimal digits each.
  ///
  /// Returns them.
  Uint8List hexToByteArray() => Uint8List.fromList(<int>[
    for (var index = 0; index < length; index += 2)
      int.parse(substring(index, index + 2), radix: 16),
  ]);
}
