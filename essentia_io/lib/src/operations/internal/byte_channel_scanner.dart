/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:typed_data';

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_io/src/buffer/buffer.dart';
import 'package:essentia_io/src/channel/byte_channel.dart';
import 'package:essentia_io/src/channel/byte_read_channel.dart';
import 'package:essentia_io/src/channel/byte_write_channel.dart';
import 'package:essentia_io/src/exception/io_exception.dart';
import 'package:meta/meta.dart';

/// Copies the bytes of a channel to another up to a delimiter, Ktor's
/// `ByteChannelScanner`: a Knuth-Morris-Pratt search that reads every byte
/// once and keeps only what may still turn out to be the delimiter.
@internal
final class ByteChannelScanner {
  /// Creates the scanner of [_channel] for [matchString], which copies to
  /// [_writeChannel] at most [_limit] bytes.
  ///
  /// Throws an [ArgumentError] for an empty [matchString].
  ByteChannelScanner(
    this._channel,
    ByteString matchString,
    this._writeChannel,
    this._limit,
  ) : _match = matchString.bytes,
      _table = _partialMatchTable(matchString.bytes),
      _input = _channel.readBuffer {
    if (_match.isEmpty) {
      throw ArgumentError.value(
        matchString,
        'matchString',
        'An empty delimiter cannot be scanned for',
      );
    }
  }

  /// The channel read from.
  final ByteReadChannel _channel;

  /// The delimiter.
  final Uint8List _match;

  /// Where the bytes before the delimiter go.
  final ByteWriteChannel _writeChannel;

  /// The most bytes copied before the delimiter.
  final int _limit;

  /// The bytes of the channel.
  final Buffer _input;

  /// For every prefix of the delimiter, the length of its longest proper
  /// prefix that is also a suffix.
  final Uint32List _table;

  /// The bytes that match the start of the delimiter so far.
  final _partial = Buffer();

  /// The bytes copied so far.
  var _bytesRead = 0;

  /// How many bytes of the delimiter matched so far.
  var _matchIndex = 0;

  /// Copies the bytes up to the next delimiter, which it reads and drops.
  ///
  /// Returns the number of bytes copied.
  ///
  /// Throws an [IoException] when the limit is exceeded, or when the
  /// channel ends without the delimiter unless [ignoreMissing], which
  /// copies what is left instead.
  Future<int> findNext({bool ignoreMissing = false}) async {
    _bytesRead = 0;
    while (!_input.exhausted || await _channel.awaitContent()) {
      await _advanceToNextPotentialMatch();
      if (await _checkFullMatch()) {
        await _writeChannel.flush();
        return _bytesRead;
      }
    }
    if (!ignoreMissing) {
      throw IoException(
        'Expected "${_singleLine()}" but encountered end of input',
      );
    }
    _bytesRead += _writeChannel.writeBuffer.writeBuffer(_partial);
    await _writeChannel.flush();
    return _bytesRead;
  }

  /// Copies the bytes up to the next one that starts the delimiter.
  Future<void> _advanceToNextPotentialMatch() async {
    while (!_input.exhausted || await _channel.awaitContent()) {
      final int next = _input.indexOf(_match[0]);
      if (next == -1) {
        _checkBounds(_input.size);
        _bytesRead += _writeChannel.writeBuffer.writeBuffer(_input);
        await _flushIfNeeded();
        continue;
      }
      _checkBounds(next);
      _bytesRead += _writeChannel.writeBuffer.writeBuffer(_input, next);
      await _flushIfNeeded();
      return;
    }
  }

  /// Reads byte by byte while they match the delimiter, and copies the
  /// bytes that turn out not to be part of it.
  ///
  /// Returns `true` once the whole delimiter matched.
  Future<bool> _checkFullMatch() async {
    while (!_input.exhausted || await _channel.awaitContent()) {
      final int byte = _input.readByte();
      if (_matchIndex > 0 && byte != _match[_matchIndex]) {
        final int previous = _matchIndex;
        while (_matchIndex > 0 && byte != _match[_matchIndex]) {
          _matchIndex = _table[_matchIndex - 1];
        }
        final int retained = previous - _matchIndex;
        _checkBounds(retained);
        _bytesRead += _writeChannel.writeBuffer.writeBuffer(_partial, retained);
        if (_matchIndex == 0 && byte != _match[0]) {
          _writeChannel.writeBuffer.writeByte(byte);
          _bytesRead++;
          return false;
        }
      }
      _matchIndex++;
      if (_matchIndex == _match.length) {
        _partial.clear();
        _matchIndex = 0;
        return true;
      }
      _partial.writeByte(byte);
    }
    return false;
  }

  /// Flushes the copied bytes once there are many or the channel flushes
  /// every write, Ktor's `flushIfNeeded`.
  Future<void> _flushIfNeeded() async {
    if (_writeChannel.autoFlush ||
        _writeChannel.writeBuffer.size >= ByteChannel.maxSize) {
      await _writeChannel.flush();
    }
  }

  /// Checks that copying [extra] more bytes stays within the limit.
  ///
  /// Throws an [IoException] when it does not.
  void _checkBounds(int extra) {
    if (_bytesRead + extra > _limit) {
      throw IoException(
        'Limit of $_limit bytes exceeded while searching for '
        '"${_singleLine()}"',
      );
    }
  }

  /// The delimiter as text on one line, for a message.
  ///
  /// Returns it with line feeds escaped.
  String _singleLine() => Charsets.utf8
      .decode(_match)
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r');

  /// The partial match table of [match].
  ///
  /// Returns it.
  static Uint32List _partialMatchTable(Uint8List match) {
    final table = Uint32List(match.length);
    var length = 0;
    for (var index = 1; index < match.length; index++) {
      while (length > 0 && match[index] != match[length]) {
        length = table[length - 1];
      }
      if (match[index] == match[length]) {
        length++;
      }
      table[index] = length;
    }
    return table;
  }
}
