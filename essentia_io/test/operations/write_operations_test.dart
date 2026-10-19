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
import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_coroutines/testing.dart';
import 'package:essentia_io/essentia_io.dart';
import 'package:test/test.dart';

/// Covers the writing operations of a channel.
void main() {
  test('writes numbers, bytes and text', () async {
    final channel = ByteChannel();

    await channel.writeByte(0x1FF);
    await channel.writeShort(0x0102);
    await channel.writeInt(0x03040506, endian: Endian.little);
    await channel.writeLong(7);
    await channel.writeFloat(1.5);
    await channel.writeDouble(2, endian: Endian.little);
    await channel.writeFully([9, 8, 7], 1);
    await channel.writeByteString(ByteString(const [6]));
    await channel.writePacket(Buffer()..write([5]));
    await channel.writeString('é');
    await channel.writeString('é', charset: Charsets.iso88591);
    await channel.flushAndClose();

    expect(await channel.readByte(), 0xFF);
    expect(await channel.readShort(), 0x0102);
    expect(await channel.readInt(endian: Endian.little), 0x03040506);
    expect(await channel.readLong(), 7);
    expect(await channel.readFloat(), 1.5);
    expect(await channel.readDouble(endian: Endian.little), 2);
    expect(await channel.readBytes(4), [8, 7, 6, 5]);
    expect(await channel.toBytes(), [0xC3, 0xA9, 0xE9]);
  });

  test('keeps the bytes until a flush unless it flushes every write', () async {
    final manual = ByteChannel();
    final automatic = ByteChannel(autoFlush: true);

    await manual.writeByte(1);
    await automatic.writeByte(1);

    expect(manual.availableForRead, 0);
    expect(automatic.availableForRead, 1);
    expect(manual.availableForWrite, ByteChannel.maxSize - 1);
  });

  test(
    'flushes once a whole channel of bytes waits',
    () => runTest((it) async {
      final channel = ByteChannel();
      final Job writing = it.launch(
        (it) => channel.writeFully(Uint8List(ByteChannel.maxSize)),
      );
      it.runCurrent();

      final bool waited = writing.isActive;
      final int read = (await channel.readRemaining(ByteChannel.maxSize)).size;
      await writing.join();

      expect(waited, isTrue);
      expect(read, ByteChannel.maxSize);
    }),
  );

  test('waits for free space', () async {
    final channel = ByteChannel();
    await channel.writeByte(1);

    await channel.awaitFreeSpace();

    expect(channel.availableForRead, 1);
  });

  test('fails to write to a channel that failed', () async {
    final channel = ByteChannel()..cancel(const EofException('gone'));

    await expectLater(
      channel.writeByte(1),
      throwsA(isA<ClosedWriteChannelException>()),
    );
  });

  test('fails to write once a reader cancelled a counted channel', () async {
    final channel = ByteChannel();
    final CountedByteWriteChannel counted = channel.asCountedWriteChannel();
    final ByteReadChannel reader = channel
      ..cancel(const EofException('reader gone'));

    expect(reader.isClosedForRead, isTrue);
    await expectLater(
      counted.writeByte(2),
      throwsA(isA<ClosedWriteChannelException>()),
    );
  });
}
