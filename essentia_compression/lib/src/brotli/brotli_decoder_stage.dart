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

/// What a `BrotliStreamDecoder` reads next.
@internal
enum BrotliDecoderStage {
  /// The stream header, the size of the window.
  streamHeader,

  /// The header of a meta-block.
  metaBlockHeader,

  /// The bytes of a metadata block, skipped.
  metadata,

  /// The bytes of an uncompressed meta-block.
  uncompressed,

  /// The insert-and-copy length of the next command.
  command,

  /// The literals of the current command.
  literals,

  /// The distance of the current command.
  distance,

  /// The copy of the current command.
  copy,

  /// Nothing: the stream ended.
  done,
}
