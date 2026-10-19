/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:math';

import 'package:meta/meta.dart';

/// The length of the trailer of a zlib stream: its Adler-32.
const _trailerLength = 4;

/// The shortest zlib stream: a header of two bytes, the two bytes of an
/// empty deflate stream and the trailer.
const _shortest = 8;

/// Checks the frame of one zlib stream, RFC 1950, around the data a
/// platform decompresses: that its header is that of deflate without a
/// preset dictionary, and that its trailer matches what came out.
///
/// It sees every chunk of the compressed data on its way to the platform,
/// checks the header as soon as it has its two bytes, remembers the last
/// four, and checks them against the Adler-32 of the decompressed data at
/// the end. That catches data that is cut short or followed by more data,
/// which the zlib of `dart:io` would pass silently.
@internal
final class ZlibFrameCheck {
  /// Creates the check of a stream nothing of which was seen yet.
  ZlibFrameCheck();

  /// The first bytes seen, at most two.
  final _first = <int>[];

  /// The last bytes seen, at most four.
  var _last = const <int>[];

  /// How many bytes were seen.
  var _length = 0;

  /// Sees [chunk] of the compressed data.
  ///
  /// Returns [chunk], unchanged.
  ///
  /// Throws a [FormatException] once the header is not that of a zlib
  /// stream of deflate data without a preset dictionary.
  List<int> see(List<int> chunk) {
    _length += chunk.length;
    final complete = _first.length == 2;
    for (final int byte in chunk.take(2 - _first.length)) {
      _first.add(byte & 0xFF);
    }
    if (!complete && _first.length == 2) {
      _checkHeader(_first[0], _first[1]);
    }
    if (chunk.length >= _trailerLength) {
      _last = chunk.sublist(chunk.length - _trailerLength);
      return chunk;
    }
    final joined = <int>[..._last, ...chunk];
    _last = joined.sublist(max(0, joined.length - _trailerLength));
    return chunk;
  }

  /// Checks the trailer against the [adler] of the decompressed data.
  ///
  /// Throws a [FormatException] if the data is too short to be zlib, or
  /// the trailer does not match.
  void verify(int adler) {
    if (_length < _shortest) {
      throw FormatException(
        'The data is not zlib: $_length bytes are too short for a zlib '
        'stream',
      );
    }
    final int stored =
        (_last[0] & 0xFF) * 0x1000000 +
        (_last[1] & 0xFF) * 0x10000 +
        (_last[2] & 0xFF) * 0x100 +
        (_last[3] & 0xFF);
    if (stored != adler) {
      throw const FormatException(
        'The zlib data is corrupt: the Adler-32 of its trailer does not '
        'match the decompressed data; it is cut short, damaged or followed '
        'by more data',
      );
    }
  }

  /// Checks the header of compression method [cmf] and flags [flg].
  ///
  /// Throws a [FormatException] when it is not deflate with a window of at
  /// most 32 KiB, its check bits are wrong, or it asks for a preset
  /// dictionary.
  static void _checkHeader(int cmf, int flg) {
    final bool deflate = cmf & 0x0F == 8 && cmf >> 4 <= 7;
    if (!deflate || (cmf * 256 + flg) % 31 != 0) {
      throw const FormatException(
        'The data is not zlib: its header is not that of a zlib stream of '
        'deflate data',
      );
    }
    if (flg & 0x20 != 0) {
      throw const FormatException(
        'The zlib data asks for a preset dictionary, which is not supported',
      );
    }
  }
}
