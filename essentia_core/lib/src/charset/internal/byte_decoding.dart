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

/// The state of decoding one sequence of bytes, chunk by chunk.
@internal
abstract interface class ByteDecoding {
  /// Decodes the bytes of [chunk] from [start] to [end].
  ///
  /// Returns the text they complete; bytes that start a character the
  /// next chunk ends are kept.
  String add(List<int> chunk, int start, int end);

  /// Ends the sequence.
  ///
  /// Returns what the kept bytes decode to: a replacement character for
  /// an incomplete one.
  String close();
}
