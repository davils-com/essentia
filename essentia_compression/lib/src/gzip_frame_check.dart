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

/// The first three bytes of every gzip member: its magic number and the
/// deflate method.
const _head = <int>[0x1F, 0x8B, 0x08];

/// The length of the trailer of a gzip member: its CRC-32 and its length.
const _trailerLength = 8;

/// The shortest gzip member: a header of ten bytes, the two bytes of an
/// empty deflate stream and the trailer.
const _shortest = 20;

/// Checks the frame of one gzip member around the data a platform
/// decompresses: that it starts as gzip does, and that its trailer matches
/// what came out.
///
/// It sees every chunk of the compressed data on its way to the platform,
/// remembers the first three bytes and the last eight, and checks them
/// against the CRC-32 and the length of the decompressed data at the end.
/// That catches data that is cut short or followed by more data, which
/// the zlib of `dart:io` would pass silently, unless what follows ends in
/// the same eight bytes as the member does.
@internal
final class GzipFrameCheck {
  /// Creates the check of a member nothing of which was seen yet.
  GzipFrameCheck();

  /// The first bytes seen, at most three.
  final _first = <int>[];

  /// The last bytes seen, at most eight.
  var _last = const <int>[];

  /// How many bytes were seen.
  var _length = 0;

  /// Sees [chunk] of the compressed data.
  ///
  /// Returns [chunk], unchanged.
  ///
  /// Throws a [FormatException] once the data does not start as gzip.
  List<int> see(List<int> chunk) {
    _length += chunk.length;
    for (final int byte in chunk.take(_head.length - _first.length)) {
      _first.add(byte & 0xFF);
    }
    for (var index = 0; index < _first.length; index++) {
      if (_first[index] != _head[index]) {
        throw const FormatException(
          'The data is not gzip: it does not start with the gzip magic '
          'number and the deflate method',
        );
      }
    }
    if (chunk.length >= _trailerLength) {
      _last = chunk.sublist(chunk.length - _trailerLength);
      return chunk;
    }
    final joined = <int>[..._last, ...chunk];
    _last = joined.sublist(max(0, joined.length - _trailerLength));
    return chunk;
  }

  /// Checks the trailer against the [crc] and the [length] of the
  /// decompressed data.
  ///
  /// Throws a [FormatException] if the data is too short to be gzip, or
  /// the trailer does not match.
  void verify(int crc, int length) {
    if (_length < _shortest) {
      throw FormatException(
        'The data is not gzip: $_length bytes are too short for a gzip '
        'member',
      );
    }
    if (_word(0) != crc) {
      throw const FormatException(
        'The gzip data is corrupt: the CRC-32 of its trailer does not match '
        'the decompressed data; it is cut short, damaged or followed by '
        'more data',
      );
    }
    if (_word(4) != length % 0x100000000) {
      throw const FormatException(
        'The gzip data is corrupt: the length in its trailer does not match '
        'the decompressed data',
      );
    }
  }

  /// The little-endian 32-bit word at [offset] of the trailer.
  ///
  /// Returns it, 0 to 2^32 - 1.
  int _word(int offset) =>
      (_last[offset] & 0xFF) +
      (_last[offset + 1] & 0xFF) * 0x100 +
      (_last[offset + 2] & 0xFF) * 0x10000 +
      (_last[offset + 3] & 0xFF) * 0x1000000;
}
