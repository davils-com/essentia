/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_io/src/buffer/buffer.dart';
import 'package:essentia_io/src/channel/byte_read_channel.dart';
import 'package:essentia_io/src/channel/byte_write_channel.dart';
import 'package:essentia_io/src/channel/counted_byte_read_channel.dart';
import 'package:essentia_io/src/channel/line_ending.dart';
import 'package:essentia_io/src/exception/eof_exception.dart';
import 'package:essentia_io/src/operations/internal/byte_channel_scanner.dart';
import 'package:essentia_io/src/operations/internal/line_reader.dart';

/// What a reader does with a [ByteReadChannel]: read numbers, bytes,
/// lines and everything that is left, copy to a writer, and scan for a
/// delimiter.
///
/// Every operation waits for the bytes it needs and fails with the
/// [ByteReadChannel.closedCause] of a channel that failed.
extension ByteReadChannelOperations on ByteReadChannel {
  /// The number of bytes that may be read without waiting.
  int get availableForRead => readBuffer.size;

  /// Waits for a byte and tells whether there is none.
  ///
  /// Returns `true` when the channel ended without one.
  Future<bool> exhausted() async {
    if (readBuffer.exhausted) {
      await awaitContent();
    }
    return readBuffer.exhausted;
  }

  /// Reads everything that is left.
  ///
  /// Returns the bytes.
  Future<Uint8List> toBytes() async => (await readRemaining()).readBytes();

  /// Reads one byte.
  ///
  /// Returns it, 0 to 255.
  ///
  /// Throws an [EofException] when the channel ends first.
  Future<int> readByte() async {
    await _awaitUntilReadable(1);
    return readBuffer.readByte();
  }

  /// Reads a signed 16-bit number.
  ///
  /// Returns it.
  ///
  /// Throws an [EofException] when the channel ends first.
  Future<int> readShort({Endian endian = Endian.big}) async {
    await _awaitUntilReadable(2);
    return readBuffer.readShort(endian: endian);
  }

  /// Reads a signed 32-bit number.
  ///
  /// Returns it.
  ///
  /// Throws an [EofException] when the channel ends first.
  Future<int> readInt({Endian endian = Endian.big}) async {
    await _awaitUntilReadable(4);
    return readBuffer.readInt(endian: endian);
  }

  /// Reads a signed 64-bit number.
  ///
  /// Returns it.
  ///
  /// Throws an [EofException] when the channel ends first, and a
  /// [FormatException] on the web compiled to JavaScript for a number
  /// beyond 2^53.
  Future<int> readLong({Endian endian = Endian.big}) async {
    await _awaitUntilReadable(8);
    return readBuffer.readLong(endian: endian);
  }

  /// Reads an IEEE 754 single precision number.
  ///
  /// Returns it.
  ///
  /// Throws an [EofException] when the channel ends first.
  Future<double> readFloat({Endian endian = Endian.big}) async {
    await _awaitUntilReadable(4);
    return readBuffer.readFloat(endian: endian);
  }

  /// Reads an IEEE 754 double precision number.
  ///
  /// Returns it.
  ///
  /// Throws an [EofException] when the channel ends first.
  Future<double> readDouble({Endian endian = Endian.big}) async {
    await _awaitUntilReadable(8);
    return readBuffer.readDouble(endian: endian);
  }

  /// Reads everything that is left, or at most [max] bytes.
  ///
  /// Returns the bytes in a buffer.
  ///
  /// Throws [ByteReadChannel.closedCause] once the channel failed.
  Future<Buffer> readRemaining([int? max]) async {
    final result = Buffer();
    int remaining = max ?? unlimitedLine;
    while (remaining > 0 && !isClosedForRead) {
      if (readBuffer.exhausted) {
        await awaitContent();
      }
      final int count = math.min(remaining, readBuffer.size);
      result.writeBuffer(readBuffer, count);
      remaining -= count;
    }
    _rethrowCloseCause();
    return result;
  }

  /// Reads exactly [count] bytes.
  ///
  /// Returns them in a buffer.
  ///
  /// Throws an [EofException] when the channel ends first.
  Future<Buffer> readPacket(int count) async {
    RangeError.checkNotNegative(count, 'count');
    final result = Buffer();
    while (result.size < count) {
      if (readBuffer.exhausted) {
        await awaitContent();
      }
      if (isClosedForRead) {
        break;
      }
      result.writeBuffer(
        readBuffer,
        math.min(readBuffer.size, count - result.size),
      );
    }
    if (result.size < count) {
      throw EofException(
        'Not enough data available, required $count bytes but only '
        '${result.size} available',
      );
    }
    return result;
  }

  /// Reads exactly [count] bytes.
  ///
  /// Returns them.
  ///
  /// Throws an [EofException] when the channel ends first.
  Future<Uint8List> readBytes(int count) async =>
      (await readPacket(count)).readBytes();

  /// Reads at most [length] bytes into [destination] from [offset], as many
  /// as have arrived, waiting for one when none has.
  ///
  /// Returns the number of bytes read, or -1 when the channel ended.
  Future<int> readAvailable(
    Uint8List destination, [
    int offset = 0,
    int? length,
  ]) async {
    if (isClosedForRead) {
      return -1;
    }
    if (readBuffer.exhausted) {
      await awaitContent();
    }
    if (isClosedForRead) {
      return -1;
    }
    return readBuffer.readAvailable(destination, offset, length);
  }

  /// Fills [destination] from [start] to [end], the end by default.
  ///
  /// Throws an [EofException] when the channel ends first.
  Future<void> readFully(
    Uint8List destination, [
    int start = 0,
    int? end,
  ]) async {
    final int stop = RangeError.checkValidRange(start, end, destination.length);
    if (stop > start && isClosedForRead) {
      throw const EofException('Channel is already closed');
    }
    var offset = start;
    while (offset < stop) {
      if (readBuffer.exhausted) {
        await awaitContent();
      }
      if (isClosedForRead) {
        throw const EofException('Channel is already closed');
      }
      offset += readBuffer.readAvailable(destination, offset, stop - offset);
    }
  }

  /// Drops at most [max] bytes, everything that is left by default.
  ///
  /// Returns the number of bytes dropped.
  Future<int> discard([int? max]) async {
    final int limit = max ?? unlimitedLine;
    var remaining = limit;
    while (remaining > 0 && !isClosedForRead) {
      if (availableForRead == 0) {
        await awaitContent();
      }
      final int count = math.min(remaining, readBuffer.size);
      readBuffer.discard(count);
      remaining -= count;
    }
    return limit - remaining;
  }

  /// Drops exactly [count] bytes.
  ///
  /// Throws an [EofException] when the channel ends first.
  Future<void> discardExact(int count) async {
    if (await discard(count) < count) {
      throw EofException('Unable to discard $count bytes');
    }
  }

  /// Copies every byte to [channel], flushing as it goes, at most [limit]
  /// bytes.
  ///
  /// Returns the number of bytes copied.
  ///
  /// Throws what the copy failed with, after cancelling both channels with
  /// it.
  Future<int> copyTo(ByteWriteChannel channel, {int? limit}) async {
    final int most = limit ?? unlimitedLine;
    var remaining = most;
    try {
      while (remaining > 0 && !isClosedForRead) {
        if (readBuffer.exhausted) {
          await awaitContent();
        }
        final int count = math.min(remaining, readBuffer.size);
        channel.writeBuffer.writeBuffer(readBuffer, count);
        remaining -= count;
        await channel.flush();
      }
      _rethrowCloseCause();
    } on Object catch (error) {
      cancel(error);
      channel.cancel(error);
      rethrow;
    }
    return most - remaining;
  }

  /// Copies every byte to [channel] and closes it once the bytes end.
  ///
  /// Returns the number of bytes copied.
  ///
  /// Throws what the copy failed with, after cancelling both channels with
  /// it.
  Future<int> copyAndClose(ByteWriteChannel channel) async {
    final int copied = await copyTo(channel);
    await channel.flushAndClose();
    return copied;
  }

  /// Reads a line of UTF-8, ending at LF or CR LF, with [lineEnding]
  /// lenient also at a CR alone; a last line without an ending counts.
  ///
  /// Returns the line without its ending, or `null` when the channel ended
  /// before.
  ///
  /// Throws a `TooLongLineException` for a line beyond 2^53 bytes.
  Future<String?> readLine({
    LineEnding lineEnding = LineEnding.defaultEnding,
  }) async {
    final result = StringBuffer();
    final int read = await readLineTo(result, lineEnding: lineEnding);
    return read >= 0 ? result.toString() : null;
  }

  /// Reads a line of UTF-8 into [out], as [readLine] does.
  ///
  /// Returns the number of bytes of the line, or -1 when the channel ended
  /// before.
  Future<int> readLineTo(
    StringSink out, {
    LineEnding lineEnding = LineEnding.defaultEnding,
  }) => LineReader(
    this,
    out,
    unlimitedLine,
    lenient: lineEnding == LineEnding.lenient,
    strict: false,
  ).read();

  /// Reads a line of UTF-8 of at most [limit] bytes that must have its
  /// ending.
  ///
  /// Returns the line without its ending, or `null` when the channel ended
  /// before.
  ///
  /// Throws a `TooLongLineException` for a longer line, and an
  /// [EofException] for a last line without an ending.
  Future<String?> readLineStrict({
    int? limit,
    LineEnding lineEnding = LineEnding.defaultEnding,
  }) async {
    final result = StringBuffer();
    final int read = await readLineStrictTo(
      result,
      limit: limit,
      lineEnding: lineEnding,
    );
    return read >= 0 ? result.toString() : null;
  }

  /// Reads a line of UTF-8 into [out], as [readLineStrict] does.
  ///
  /// Returns the number of bytes of the line, or -1 when the channel ended
  /// before.
  Future<int> readLineStrictTo(
    StringSink out, {
    int? limit,
    LineEnding lineEnding = LineEnding.defaultEnding,
  }) {
    final int most = limit ?? unlimitedLine;
    RangeError.checkNotNegative(most, 'limit');
    return LineReader(
      this,
      out,
      most,
      lenient: lineEnding == LineEnding.lenient,
      strict: true,
    ).read();
  }

  /// Copies the bytes up to [matchString] to [writeChannel] and drops the
  /// delimiter, at most [limit] bytes, and flushes what it copied.
  ///
  /// Returns the number of bytes copied.
  ///
  /// Throws an `IoException` when the limit is exceeded, or when the
  /// channel ends without the delimiter unless [ignoreMissing], which then
  /// copies what is left; an [ArgumentError] for an empty [matchString].
  Future<int> readUntil(
    ByteString matchString,
    ByteWriteChannel writeChannel, {
    int? limit,
    bool ignoreMissing = false,
  }) => ByteChannelScanner(
    this,
    matchString,
    writeChannel,
    limit ?? unlimitedLine,
  ).findNext(ignoreMissing: ignoreMissing);

  /// Drops [bytes] when they come next.
  ///
  /// Returns whether they came and were dropped.
  Future<bool> skipIfFound(ByteString bytes) async {
    if (await peek(bytes.size) == bytes) {
      await discard(bytes.size);
      return true;
    }
    return false;
  }

  /// Waits for [count] bytes and copies them without reading them.
  ///
  /// Returns them, or `null` when the channel ends first.
  Future<ByteString?> peek(int count) async {
    if (isClosedForRead) {
      return null;
    }
    if (!await awaitContent(count)) {
      return null;
    }
    return ByteString(readBuffer.peekBytes(count));
  }

  /// Throws [ByteReadChannel.closedCause] once the channel failed.
  void rethrowCloseCauseIfNeeded() {
    _rethrowCloseCause();
  }

  /// The channel that counts the bytes read through it.
  ///
  /// Returns it.
  CountedByteReadChannel asCountedReadChannel() => CountedByteReadChannel(this);

  /// Waits for [count] bytes.
  ///
  /// Throws an [EofException] when the channel ends first.
  Future<void> _awaitUntilReadable(int count) async {
    if (!await awaitContent(count)) {
      throw const EofException('Not enough data available');
    }
  }

  /// Throws [ByteReadChannel.closedCause] once the channel failed.
  void _rethrowCloseCause() {
    final Exception? cause = closedCause;
    if (cause != null) {
      throw cause;
    }
  }
}
