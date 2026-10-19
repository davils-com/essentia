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

import 'package:meta/meta.dart';

/// A run of bytes of a buffer: the bytes of [data] from [start] to [end].
///
/// A buffer reads from [start] and writes at [end]; a segment it may write
/// to is [writable], one that shares its bytes with another is not.
@internal
final class Segment {
  /// Creates the segment of [data] from [start] to [end].
  Segment(this.data, this.start, this.end, {required this.writable});

  /// Creates an empty segment a buffer may write [capacity] bytes to.
  Segment.empty(int capacity)
    : data = Uint8List(capacity),
      start = 0,
      end = 0,
      writable = true;

  /// The bytes the segment holds a run of.
  final Uint8List data;

  /// Where the unread bytes start.
  int start;

  /// Where the unread bytes end, and the next byte is written.
  int end;

  /// Whether the buffer may write behind [end].
  final bool writable;

  /// The number of unread bytes.
  int get length => end - start;

  /// The number of bytes that may still be written.
  int get room => writable ? data.length - end : 0;
}
