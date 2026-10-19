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

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_io/essentia_io.dart';
import 'package:test/test.dart';

/// [length] bytes counting up from zero.
///
/// Returns them.
Uint8List _counting(int length) => Uint8List.fromList([
  for (var index = 0; index < length; index++) index & 0xFF,
]);

/// Covers `Buffer`: writing and reading numbers, bytes and text, moving
/// segments, searching and its limits.
void main() {
  test('reads the bytes in the order they were written', () {
    final buffer = Buffer()
      ..write([1, 2, 3])
      ..writeByte(4);

    final Uint8List bytes = buffer.readBytes();

    expect(bytes, [1, 2, 3, 4]);
    expect(buffer.exhausted, isTrue);
    expect(buffer.size, 0);
  });

  test('reads a byte unsigned and keeps the low eight bits of one', () {
    final buffer = Buffer()
      ..writeByte(0x1FF)
      ..writeByte(-1);

    expect(buffer.readByte(), 0xFF);
    expect(buffer.readByte(), 0xFF);
  });

  test('writes and reads numbers big-endian by default', () {
    final buffer = Buffer()
      ..writeShort(0x1234)
      ..writeInt(0x12345678)
      ..writeLong(0x0001020304050607);

    expect(buffer.peekBytes(2), [0x12, 0x34]);
    expect(buffer.readShort(), 0x1234);
    expect(buffer.readInt(), 0x12345678);
    expect(buffer.readLong(), 0x0001020304050607);
  });

  test('writes and reads numbers little-endian', () {
    final buffer = Buffer()
      ..writeShort(0x1234, endian: Endian.little)
      ..writeInt(0x12345678, endian: Endian.little)
      ..writeLong(0x0001020304050607, endian: Endian.little);

    expect(buffer.peekBytes(2), [0x34, 0x12]);
    expect(buffer.readShort(endian: Endian.little), 0x1234);
    expect(buffer.readInt(endian: Endian.little), 0x12345678);
    expect(buffer.peekBytes(8), [7, 6, 5, 4, 3, 2, 1, 0]);
    expect(buffer.readLong(endian: Endian.little), 0x0001020304050607);
  });

  test('reads the wider numbers signed', () {
    final buffer = Buffer()
      ..writeShort(-2)
      ..writeInt(-3)
      ..writeLong(-4)
      ..write([0x80, 0x00]);

    expect(buffer.readShort(), -2);
    expect(buffer.readInt(), -3);
    expect(buffer.readLong(), -4);
    expect(buffer.readShort(), -32768);
  });

  test('keeps 53 bits of a long exact everywhere', () {
    const big = 9007199254740991;
    final buffer = Buffer()
      ..writeLong(big)
      ..writeLong(-big);

    expect(buffer.readLong(), big);
    expect(buffer.readLong(), -big);
  });

  test('keeps all 64 bits of a long off the web', () {
    final int largest = int.parse('7FFFFFFFFFFFFFFF', radix: 16);
    final int smallest = int.parse('-8000000000000000', radix: 16);
    final buffer = Buffer()
      ..writeLong(largest)
      ..write([0x80, 0, 0, 0, 0, 0, 0, 0]);

    expect(buffer.readLong(), largest);
    expect(buffer.readLong(), smallest);
  }, testOn: '!dart2js');

  test('refuses a long beyond 2^53 on JavaScript', () {
    final buffer = Buffer()
      ..write([0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]);

    expect(buffer.readLong, throwsFormatException);
    expect(buffer.exhausted, isTrue);
    expect(() => Buffer().writeLong(18014398509481984), throwsRangeError);
  }, testOn: 'dart2js');

  test('writes and reads floating point numbers', () {
    final buffer = Buffer()
      ..writeFloat(1.5)
      ..writeDouble(-2.25, endian: Endian.little);

    expect(buffer.readFloat(), 1.5);
    expect(buffer.readDouble(endian: Endian.little), -2.25);
  });

  test('writes and reads text in a charset', () {
    final buffer = Buffer()
      ..writeString('héllo')
      ..writeString('é', charset: Charsets.iso88591);

    expect(buffer.readString(count: 6), 'héllo');
    expect(buffer.readString(charset: Charsets.iso88591), 'é');
  });

  test('writes and reads byte strings', () {
    final buffer = Buffer()..writeByteString(ByteString(const [9, 8, 7]));

    expect(buffer.readByteString(2), ByteString(const [9, 8]));
    expect(buffer.readByteString(), ByteString(const [7]));
  });

  test('writes a range of a list', () {
    final buffer = Buffer()..write([1, 2, 3, 4, 5], 1, 4);

    expect(buffer.readBytes(), [2, 3, 4]);
    expect(() => Buffer().write([1], 0, 2), throwsRangeError);
  });

  test('spans segments for data larger than one', () {
    final Uint8List data = _counting(Buffer.segmentSize * 2 + 100);
    final buffer = Buffer();
    for (var start = 0; start < data.length; start += 1000) {
      buffer.write(data, start, (start + 1000).clamp(0, data.length));
    }

    expect(buffer.size, data.length);
    expect(buffer[Buffer.segmentSize + 3], data[Buffer.segmentSize + 3]);
    expect(
      buffer.readBytes(Buffer.segmentSize + 10),
      data.sublist(0, Buffer.segmentSize + 10),
    );
    expect(buffer.readBytes(), data.sublist(Buffer.segmentSize + 10));
  });

  test('writes again after reading everything', () {
    final buffer = Buffer()
      ..write([1, 2])
      ..discard(2)
      ..write([3]);

    expect(buffer.readBytes(), [3]);
  });

  test('reads what is there into a list', () {
    final buffer = Buffer()..write([1, 2, 3]);
    final destination = Uint8List(5);

    final int first = buffer.readAvailable(destination, 1, 2);
    final int second = buffer.readAvailable(destination, 3);
    final int third = buffer.readAvailable(destination);

    expect(first, 2);
    expect(second, 1);
    expect(third, 0);
    expect(destination, [0, 1, 2, 3, 0]);
    expect(() => buffer.readAvailable(destination, 4, 2), throwsRangeError);
  });

  test('peeks without reading', () {
    final buffer = Buffer()..write(_counting(Buffer.segmentSize + 5));

    final Uint8List peeked = buffer.peekBytes(Buffer.segmentSize + 2);

    expect(peeked, _counting(Buffer.segmentSize + 2));
    expect(buffer.size, Buffer.segmentSize + 5);
    expect(buffer.peekBytes(), hasLength(Buffer.segmentSize + 5));
  });

  test('drops bytes from the front across segments', () {
    final buffer = Buffer()
      ..write(_counting(Buffer.segmentSize + 5))
      ..discard(Buffer.segmentSize + 1);

    expect(buffer.readBytes(), [1, 2, 3, 4]);
  });

  test('refuses to read more than it holds and reads nothing', () {
    final buffer = Buffer()..write([1, 2, 3]);

    expect(
      () => buffer.readBytes(4),
      throwsA(
        isA<EofException>().having(
          (error) => error.message,
          'message',
          'The buffer holds 3 bytes, fewer than the 4 required',
        ),
      ),
    );
    expect(buffer.readInt, throwsA(isA<EofException>()));
    expect(() => buffer.discard(4), throwsA(isA<EofException>()));
    expect(() => buffer.peekBytes(4), throwsA(isA<EofException>()));
    expect(Buffer().readByte, throwsA(isA<EofException>()));
    expect(() => buffer.readBytes(-1), throwsRangeError);
    expect(buffer.size, 3);
  });

  test('looks at a byte by its position', () {
    final buffer = Buffer()..write([5, 6]);

    expect(buffer[1], 6);
    expect(() => buffer[2], throwsRangeError);
    expect(() => buffer[-1], throwsRangeError);
  });

  test('finds a byte within a range across segments', () {
    final buffer = Buffer()
      ..write(List<int>.filled(Buffer.segmentSize, 0))
      ..write([7, 0, 7]);

    expect(buffer.indexOf(7), Buffer.segmentSize);
    expect(buffer.indexOf(7, Buffer.segmentSize + 1), Buffer.segmentSize + 2);
    expect(buffer.indexOf(7, 0, Buffer.segmentSize), -1);
    expect(buffer.indexOf(0x107), Buffer.segmentSize);
    expect(buffer.indexOf(9), -1);
    expect(() => buffer.indexOf(7, 0, buffer.size + 1), throwsRangeError);
  });

  test('finds a run of bytes, also across segments', () {
    final buffer = Buffer()
      ..write(List<int>.filled(Buffer.segmentSize - 1, 1))
      ..write([2, 3, 2, 3, 4]);

    expect(buffer.indexOfBytes([2, 3, 4]), Buffer.segmentSize + 1);
    expect(buffer.indexOfBytes([1, 2]), Buffer.segmentSize - 2);
    expect(buffer.indexOfBytes([3, 3]), -1);
    expect(buffer.indexOfBytes([4, 5]), -1);
    expect(buffer.indexOfBytes(<int>[], 3), 3);
    expect(() => buffer.indexOfBytes([1], buffer.size + 1), throwsRangeError);
  });

  test('keeps a view it read when it writes on', () {
    final buffer = Buffer()..write([1, 2]);

    final Uint8List view = buffer.readBytes();
    buffer.write([3, 4]);

    expect(view, [1, 2]);
  });

  test('moves into a buffer it read empty before', () {
    final destination = Buffer()
      ..write([1])
      ..discard(1)
      ..writeBuffer(Buffer()..write([2, 3]));

    expect(destination.readByte(), 2);
    expect(destination.readBytes(), [3]);
  });

  test('moves whole segments and splits the last one', () {
    final source = Buffer()..write(_counting(Buffer.segmentSize + 10));
    final destination = Buffer()..write([0xAA]);

    final int moved = destination.writeBuffer(source, Buffer.segmentSize + 4);
    destination.writeByte(0xBB);

    expect(moved, Buffer.segmentSize + 4);
    expect(source.size, 6);
    expect(destination.size, Buffer.segmentSize + 6);
    expect(destination.readByte(), 0xAA);
    expect(
      destination.readBytes(Buffer.segmentSize + 4),
      _counting(Buffer.segmentSize + 4),
    );
    expect(destination.readByte(), 0xBB);
    expect(
      source.readBytes(),
      _counting(Buffer.segmentSize + 10).sublist(Buffer.segmentSize + 4),
    );
  });

  test('transfers everything either way', () {
    final first = Buffer()..write([1, 2]);
    final second = Buffer()..write([3]);

    final int out = first.transferTo(second);
    final int back = first.transferFrom(second);

    expect(out, 2);
    expect(back, 3);
    expect(first.readBytes(), [3, 1, 2]);
  });

  test('refuses to move more than the source holds or into itself', () {
    final source = Buffer()..write([1]);

    expect(() => Buffer().writeBuffer(source, 2), throwsA(isA<EofException>()));
    expect(() => source.writeBuffer(source), throwsArgumentError);
    expect(source.size, 1);
  });

  test('copies apart from itself', () {
    final buffer = Buffer()..write([1, 2]);

    final Buffer copy = buffer.copy()..writeByte(3);
    buffer.discard(1);

    expect(copy.readBytes(), [1, 2, 3]);
    expect(buffer.readBytes(), [2]);
  });

  test('forgets everything on clear', () {
    final buffer = Buffer()
      ..write([1, 2])
      ..clear();

    expect(buffer.exhausted, isTrue);
    expect(buffer.toString(), 'Buffer(size=0)');
  });
}
