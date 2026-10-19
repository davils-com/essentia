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

import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_io/src/buffer/internal/segment.dart';
import 'package:essentia_io/src/exception/eof_exception.dart';

/// Whether integers are JavaScript numbers, exact only up to 2^53, as they
/// are when compiled to JavaScript; they have 64 bits everywhere else.
const bool _javaScriptNumbers = identical(1, 1.0);

/// 2^32, the factor of the high word of a 64-bit number.
const _twoTo32 = 0x100000000;

/// The largest integer a JavaScript number holds exactly, 2^53.
const _javaScriptLimit = 9007199254740992;

/// A queue of bytes written at its end and read from its front, which
/// every byte channel is built on.
///
/// The bytes lie in segments of [segmentSize] bytes, so that writing and
/// reading move no more than they must, and moving the bytes of one buffer
/// into another hands over whole segments instead of copying them.
///
/// Numbers are written and read big-endian unless an [Endian] says
/// otherwise; [readByte] reads a byte as 0 to 255, the wider numbers are
/// signed. Reading more than the buffer holds fails with an
/// [EofException] and reads nothing.
///
/// ```dart
/// final buffer = Buffer()
///   ..writeInt(42)
///   ..writeString('hi');
/// final int answer = buffer.readInt();
/// final String text = buffer.readString();
/// ```
final class Buffer {
  /// Creates an empty buffer.
  Buffer();

  /// The size of a segment the buffer allocates to write to.
  static const segmentSize = 8192;

  /// The segments, from the front to the end.
  final _segments = ListQueue<Segment>();

  /// The number of bytes in the buffer.
  var _size = 0;

  /// The number of bytes in the buffer.
  int get size => _size;

  /// Whether the buffer holds no bytes.
  bool get exhausted => _size == 0;

  /// The byte at [index] from the front, without reading it.
  ///
  /// Returns it, 0 to 255.
  ///
  /// Throws a [RangeError] when [index] is not within [size].
  int operator [](int index) {
    RangeError.checkValidIndex(index, this, 'index', _size);
    final Iterator<Segment> segments = _segments.iterator..moveNext();
    var remaining = index;
    while (remaining >= segments.current.length) {
      remaining -= segments.current.length;
      segments.moveNext();
    }
    return segments.current.data[segments.current.start + remaining];
  }

  /// Writes [value] as one byte; only its low eight bits count.
  void writeByte(int value) {
    final Segment tail = _writableTail(1);
    tail.data[tail.end++] = value & 0xFF;
    _size++;
  }

  /// Writes the low 16 bits of [value].
  void writeShort(int value, {Endian endian = Endian.big}) {
    write(
      Uint8List(2)..buffer.asByteData().setUint16(0, value & 0xFFFF, endian),
    );
  }

  /// Writes the low 32 bits of [value].
  void writeInt(int value, {Endian endian = Endian.big}) {
    write(
      Uint8List(4)
        ..buffer.asByteData().setUint32(0, value & 0xFFFFFFFF, endian),
    );
  }

  /// Writes [value] as 64 bits.
  ///
  /// Throws a [RangeError] on the web compiled to JavaScript, where a
  /// number beyond 2^53 is not exact, for such a [value].
  void writeLong(int value, {Endian endian = Endian.big}) {
    final (int high, int low) = _words(value);
    final bytes = Uint8List(8);
    final ByteData data = bytes.buffer.asByteData();
    if (endian == Endian.big) {
      data
        ..setUint32(0, high)
        ..setUint32(4, low);
    }
    if (endian == Endian.little) {
      data
        ..setUint32(0, low, Endian.little)
        ..setUint32(4, high, Endian.little);
    }
    write(bytes);
  }

  /// Writes [value] as an IEEE 754 single precision number.
  void writeFloat(double value, {Endian endian = Endian.big}) {
    write(Uint8List(4)..buffer.asByteData().setFloat32(0, value, endian));
  }

  /// Writes [value] as an IEEE 754 double precision number.
  void writeDouble(double value, {Endian endian = Endian.big}) {
    write(Uint8List(8)..buffer.asByteData().setFloat64(0, value, endian));
  }

  /// Writes the bytes of [bytes] from [start] to [end], the end by
  /// default; of every element only its low eight bits count.
  ///
  /// Throws a [RangeError] when [start] and [end] are not a range of
  /// [bytes].
  void write(List<int> bytes, [int start = 0, int? end]) {
    final int stop = RangeError.checkValidRange(start, end, bytes.length);
    var index = start;
    while (index < stop) {
      final Segment tail = _writableTail(stop - index);
      final int count = math.min(tail.room, stop - index);
      for (var offset = 0; offset < count; offset++) {
        tail.data[tail.end + offset] = bytes[index + offset] & 0xFF;
      }
      tail.end += count;
      index += count;
    }
    _size += stop - start;
  }

  /// Writes the bytes of [bytes].
  void writeByteString(ByteString bytes) {
    write(bytes.bytes);
  }

  /// Writes [text] in [charset].
  ///
  /// Throws an [ArgumentError] for a character [charset] cannot represent.
  void writeString(String text, {Charset charset = Charsets.utf8}) {
    write(charset.encode(text));
  }

  /// Moves [count] bytes, every byte by default, from the front of
  /// [source] to the end of this buffer, handing over whole segments where
  /// it can.
  ///
  /// Returns the number of bytes moved.
  ///
  /// Throws an [EofException] when [source] holds fewer than [count]
  /// bytes, and an [ArgumentError] when [source] is this buffer.
  int writeBuffer(Buffer source, [int? count]) {
    if (identical(source, this)) {
      throw ArgumentError.value(source, 'source', 'is this buffer');
    }
    final int wanted = count ?? source._size;
    source._require(wanted);
    var remaining = wanted;
    while (remaining > 0) {
      final Segment front = source._segments.first;
      if (front.length <= remaining) {
        source._segments.removeFirst();
        _segments.add(front);
        remaining -= front.length;
        continue;
      }
      _segments.add(
        Segment(
          Uint8List.sublistView(
            front.data,
            front.start,
            front.start + remaining,
          ),
          0,
          remaining,
          writable: false,
        ),
      );
      front.start += remaining;
      remaining = 0;
    }
    source._size -= wanted;
    _size += wanted;
    return wanted;
  }

  /// Moves every byte of this buffer to the end of [destination].
  ///
  /// Returns the number of bytes moved.
  int transferTo(Buffer destination) => destination.writeBuffer(this);

  /// Moves every byte of [source] to the end of this buffer.
  ///
  /// Returns the number of bytes moved.
  int transferFrom(Buffer source) => writeBuffer(source);

  /// Reads one byte.
  ///
  /// Returns it, 0 to 255.
  ///
  /// Throws an [EofException] when the buffer is empty.
  int readByte() {
    _require(1);
    final Segment front = _segments.first;
    final int byte = front.data[front.start++];
    _size--;
    _dropEmptyFront();
    return byte;
  }

  /// Reads a signed 16-bit number.
  ///
  /// Returns it.
  ///
  /// Throws an [EofException] when the buffer holds fewer than two bytes.
  int readShort({Endian endian = Endian.big}) =>
      _numberData(2).getInt16(0, endian);

  /// Reads a signed 32-bit number.
  ///
  /// Returns it.
  ///
  /// Throws an [EofException] when the buffer holds fewer than four bytes.
  int readInt({Endian endian = Endian.big}) =>
      _numberData(4).getInt32(0, endian);

  /// Reads a signed 64-bit number.
  ///
  /// Returns it.
  ///
  /// Throws an [EofException] when the buffer holds fewer than eight
  /// bytes, and a [FormatException] on the web compiled to JavaScript for
  /// a number beyond 2^53, which a number there does not hold exactly; the
  /// bytes are read either way.
  int readLong({Endian endian = Endian.big}) {
    final ByteData data = _numberData(8);
    final big = endian == Endian.big;
    final int high = data.getInt32(big ? 0 : 4, endian);
    final int low = data.getUint32(big ? 4 : 0, endian);
    if (!_javaScriptNumbers) {
      return (high << 32) | low;
    }
    final int value = high * _twoTo32 + low;
    if (value.abs() > _javaScriptLimit) {
      throw const FormatException(
        'The 64-bit number is beyond 2^53, which a number does not hold '
        'exactly on the web',
      );
    }
    return value;
  }

  /// Reads an IEEE 754 single precision number.
  ///
  /// Returns it.
  ///
  /// Throws an [EofException] when the buffer holds fewer than four bytes.
  double readFloat({Endian endian = Endian.big}) =>
      _numberData(4).getFloat32(0, endian);

  /// Reads an IEEE 754 double precision number.
  ///
  /// Returns it.
  ///
  /// Throws an [EofException] when the buffer holds fewer than eight
  /// bytes.
  double readDouble({Endian endian = Endian.big}) =>
      _numberData(8).getFloat64(0, endian);

  /// Reads [count] bytes, every byte by default.
  ///
  /// Returns them.
  ///
  /// Throws an [EofException] when the buffer holds fewer than [count]
  /// bytes.
  Uint8List readBytes([int? count]) {
    final int wanted = count ?? _size;
    _require(wanted);
    final Segment? front = _segments.isEmpty ? null : _segments.first;
    if (front != null && front.length >= wanted) {
      final view = Uint8List.sublistView(
        front.data,
        front.start,
        front.start + wanted,
      );
      front.start += wanted;
      _size -= wanted;
      _dropEmptyFront();
      return view;
    }
    final result = Uint8List(wanted);
    _readInto(result, 0, wanted);
    return result;
  }

  /// Reads at most [length] bytes into [destination] from [offset], as
  /// many as the buffer holds.
  ///
  /// Returns the number of bytes read, 0 when the buffer is empty.
  ///
  /// Throws a [RangeError] when [offset] and [length] are not within
  /// [destination].
  int readAvailable(Uint8List destination, [int offset = 0, int? length]) {
    final int end = RangeError.checkValidRange(
      offset,
      length == null ? null : offset + length,
      destination.length,
    );
    final int count = math.min(end - offset, _size);
    _readInto(destination, offset, count);
    return count;
  }

  /// Reads [count] bytes, every byte by default, as a [ByteString].
  ///
  /// Returns them.
  ///
  /// Throws an [EofException] when the buffer holds fewer than [count]
  /// bytes.
  ByteString readByteString([int? count]) => ByteString(readBytes(count));

  /// Reads [count] bytes, every byte by default, as text in [charset].
  ///
  /// Returns the text; bytes [charset] does not define decode to U+FFFD.
  ///
  /// Throws an [EofException] when the buffer holds fewer than [count]
  /// bytes.
  String readString({int? count, Encoding charset = Charsets.utf8}) =>
      charset.decode(readBytes(count));

  /// Copies [count] bytes from the front, every byte by default, without
  /// reading them.
  ///
  /// Returns the copy.
  ///
  /// Throws an [EofException] when the buffer holds fewer than [count]
  /// bytes.
  Uint8List peekBytes([int? count]) {
    final int wanted = count ?? _size;
    _require(wanted);
    final result = Uint8List(wanted);
    var offset = 0;
    for (final Segment segment in _segments) {
      if (offset == wanted) {
        break;
      }
      final int take = math.min(segment.length, wanted - offset);
      result.setRange(offset, offset + take, segment.data, segment.start);
      offset += take;
    }
    return result;
  }

  /// Drops [count] bytes from the front.
  ///
  /// Throws an [EofException] when the buffer holds fewer than [count]
  /// bytes.
  void discard(int count) {
    _require(count);
    var remaining = count;
    while (remaining > 0) {
      final Segment front = _segments.first;
      final int take = math.min(front.length, remaining);
      front.start += take;
      remaining -= take;
      _dropEmptyFront();
    }
    _size -= count;
  }

  /// The position of the first [byte] from [start] up to [end], the end by
  /// default.
  ///
  /// Returns it, or -1 when [byte] is not there.
  ///
  /// Throws a [RangeError] when [start] and [end] are not within [size].
  int indexOf(int byte, [int start = 0, int? end]) {
    final int stop = RangeError.checkValidRange(start, end, _size);
    final int wanted = byte & 0xFF;
    var base = 0;
    for (final Segment segment in _segments) {
      if (base >= stop) {
        return -1;
      }
      final int from = math.max(start - base, 0);
      final int to = math.min(stop - base, segment.length);
      for (var index = from; index < to; index++) {
        if (segment.data[segment.start + index] == wanted) {
          return base + index;
        }
      }
      base += segment.length;
    }
    return -1;
  }

  /// The position of the first occurrence of [bytes] from [start].
  ///
  /// Returns it, or -1 when [bytes] does not occur; [start] for empty
  /// [bytes].
  ///
  /// Throws a [RangeError] when [start] is not within [size].
  int indexOfBytes(List<int> bytes, [int start = 0]) {
    RangeError.checkValueInInterval(start, 0, _size, 'start');
    if (bytes.isEmpty) {
      return start;
    }
    int candidate = indexOf(bytes[0], start);
    while (candidate != -1 && candidate + bytes.length <= _size) {
      if (_matchesAt(candidate, bytes)) {
        return candidate;
      }
      candidate = indexOf(bytes[0], candidate + 1);
    }
    return -1;
  }

  /// Copies the buffer, so that reading the copy leaves this one as it is.
  ///
  /// Returns the copy.
  Buffer copy() => Buffer()..write(peekBytes());

  /// Drops every byte.
  void clear() {
    _segments.clear();
    _size = 0;
  }

  /// Describes the buffer by its size, never by its bytes.
  ///
  /// Returns `Buffer(size=<size>)`.
  @override
  String toString() => 'Buffer(size=$_size)';

  /// The end segment, writable with room, or a new one of room for
  /// [wanted] bytes, at least [segmentSize].
  ///
  /// Returns it.
  Segment _writableTail(int wanted) {
    final Segment? tail = _segments.isEmpty ? null : _segments.last;
    if (tail != null && tail.room > 0) {
      return tail;
    }
    final fresh = Segment.empty(math.max(segmentSize, wanted));
    _segments.add(fresh);
    return fresh;
  }

  /// Reads [count] bytes into [destination] from [offset]; the buffer
  /// holds them.
  void _readInto(Uint8List destination, int offset, int count) {
    var written = 0;
    while (written < count) {
      final Segment front = _segments.first;
      final int take = math.min(front.length, count - written);
      destination.setRange(
        offset + written,
        offset + written + take,
        front.data,
        front.start,
      );
      front.start += take;
      written += take;
      _dropEmptyFront();
    }
    _size -= count;
  }

  /// Reads the [count] bytes of a number.
  ///
  /// Returns a view of them.
  ///
  /// Throws an [EofException] when the buffer holds fewer.
  ByteData _numberData(int count) {
    _require(count);
    final bytes = Uint8List(count);
    _readInto(bytes, 0, count);
    return bytes.buffer.asByteData();
  }

  /// Whether [bytes] lie at [position]; the buffer holds as many bytes
  /// from there.
  ///
  /// Returns `true` when they do.
  bool _matchesAt(int position, List<int> bytes) {
    for (var index = 0; index < bytes.length; index++) {
      if (this[position + index] != bytes[index] & 0xFF) {
        return false;
      }
    }
    return true;
  }

  /// Drops the front segment once it is read; its bytes are never written
  /// again, so a view [readBytes] handed out of them stays as it is.
  void _dropEmptyFront() {
    if (_segments.isNotEmpty && _segments.first.length == 0) {
      _segments.removeFirst();
    }
  }

  /// Checks that the buffer holds [count] bytes.
  ///
  /// Throws an [EofException] when it holds fewer, and a [RangeError] for
  /// a negative [count].
  void _require(int count) {
    RangeError.checkNotNegative(count, 'count');
    if (_size < count) {
      throw EofException(
        'The buffer holds $_size bytes, fewer than the $count required',
      );
    }
  }

  /// The high and the low 32-bit word of [value].
  ///
  /// Returns them, each unsigned.
  ///
  /// Throws a [RangeError] on the web compiled to JavaScript for a value
  /// beyond 2^53.
  static (int, int) _words(int value) {
    if (!_javaScriptNumbers) {
      return ((value >> 32) & 0xFFFFFFFF, value & 0xFFFFFFFF);
    }
    RangeError.checkValueInInterval(
      value,
      -_javaScriptLimit,
      _javaScriptLimit,
      'value',
    );
    final int high = (value / _twoTo32).floor();
    final int low = value - high * _twoTo32;
    return (high & 0xFFFFFFFF, low);
  }
}
