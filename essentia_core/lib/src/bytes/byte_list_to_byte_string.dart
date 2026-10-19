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

import 'package:essentia_core/src/bytes/byte_string.dart';
import 'package:meta/meta.dart';

/// Turns any list of bytes into a [ByteString].
extension ByteListToByteString on List<int> {
  /// Copies the bytes into a [ByteString].
  ///
  /// Returns the byte string.
  @useResult
  ByteString toByteString() => ByteString(this);
}
