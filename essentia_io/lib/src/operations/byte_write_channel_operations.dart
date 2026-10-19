/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:convert';
import 'dart:typed_data';

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_io/src/buffer/buffer.dart';
import 'package:essentia_io/src/channel/byte_channel.dart';
import 'package:essentia_io/src/channel/byte_write_channel.dart';
import 'package:essentia_io/src/channel/counted_byte_write_channel.dart';

/// What a writer does with a [ByteWriteChannel]: write numbers, bytes and
/// text.
///
/// Every operation writes to the [ByteWriteChannel.writeBuffer] and
/// flushes once the channel flushes every write or [ByteChannel.maxSize]
/// bytes are waiting; it fails with the cause of a channel that failed.
extension ByteWriteChannelOperations on ByteWriteChannel {
  /// The number of bytes that may be written before an operation flushes.
  int get availableForWrite => ByteChannel.maxSize - writeBuffer.size;

  /// Writes the low eight bits of [value].
  Future<void> writeByte(int value) async {
    writeBuffer.writeByte(value);
    await _flushIfNeeded();
  }

  /// Writes the low 16 bits of [value].
  Future<void> writeShort(int value, {Endian endian = Endian.big}) async {
    writeBuffer.writeShort(value, endian: endian);
    await _flushIfNeeded();
  }

  /// Writes the low 32 bits of [value].
  Future<void> writeInt(int value, {Endian endian = Endian.big}) async {
    writeBuffer.writeInt(value, endian: endian);
    await _flushIfNeeded();
  }

  /// Writes [value] as 64 bits.
  ///
  /// Throws a [RangeError] on the web compiled to JavaScript for a value
  /// beyond 2^53.
  Future<void> writeLong(int value, {Endian endian = Endian.big}) async {
    writeBuffer.writeLong(value, endian: endian);
    await _flushIfNeeded();
  }

  /// Writes [value] as an IEEE 754 single precision number.
  Future<void> writeFloat(double value, {Endian endian = Endian.big}) async {
    writeBuffer.writeFloat(value, endian: endian);
    await _flushIfNeeded();
  }

  /// Writes [value] as an IEEE 754 double precision number.
  Future<void> writeDouble(double value, {Endian endian = Endian.big}) async {
    writeBuffer.writeDouble(value, endian: endian);
    await _flushIfNeeded();
  }

  /// Writes the bytes of [bytes] from [start] to [end], the end by default.
  ///
  /// Throws a [RangeError] when [start] and [end] are not a range of
  /// [bytes].
  Future<void> writeFully(List<int> bytes, [int start = 0, int? end]) async {
    writeBuffer.write(bytes, start, end);
    await _flushIfNeeded();
  }

  /// Writes the bytes of [bytes].
  Future<void> writeByteString(ByteString bytes) async {
    writeBuffer.writeByteString(bytes);
    await _flushIfNeeded();
  }

  /// Moves every byte of [source] into the channel.
  Future<void> writePacket(Buffer source) async {
    writeBuffer.writeBuffer(source);
    await _flushIfNeeded();
  }

  /// Writes [text] in [charset], UTF-8 by default.
  ///
  /// Throws an [ArgumentError] for a character [charset] cannot represent.
  Future<void> writeString(
    String text, {
    Encoding charset = Charsets.utf8,
  }) async {
    writeBuffer.write(charset.encode(text));
    await _flushIfNeeded();
  }

  /// Waits until the reader took enough bytes to write again.
  Future<void> awaitFreeSpace() => flush();

  /// The channel that counts the bytes written through it.
  ///
  /// Returns it.
  CountedByteWriteChannel asCountedWriteChannel() =>
      CountedByteWriteChannel(this);

  /// Flushes once the channel flushes every write or the bytes waiting
  /// reach [ByteChannel.maxSize].
  ///
  /// Throws the cause of a channel that failed.
  Future<void> _flushIfNeeded() async {
    final Exception? cause = closedCause;
    if (cause != null) {
      throw cause;
    }
    if (autoFlush || writeBuffer.size >= ByteChannel.maxSize) {
      await flush();
    }
  }
}
