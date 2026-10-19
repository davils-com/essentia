/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
