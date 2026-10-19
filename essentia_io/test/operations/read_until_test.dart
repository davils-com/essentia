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

import 'dart:convert';

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/testing.dart';
import 'package:essentia_io/essentia_io.dart';
import 'package:test/test.dart';

import '../support/arriving_channel.dart';

/// The delimiter of the tests.
final ByteString _boundary = '--ab'.encodeToByteString();

/// The text a channel received.
///
/// Returns it.
Future<String> _text(ByteChannel channel) async =>
    utf8.decode(await channel.toBytes());

/// Covers scanning a channel for a delimiter.
void main() {
  test('copies the bytes before the delimiter and drops it', () async {
    final source = ByteReadChannel.fromText('first--absecond--ab');
    final target = ByteChannel();

    final int first = await source.readUntil(_boundary, target);
    final int second = await source.readUntil(_boundary, target);
    target.close();

    expect(first, 5);
    expect(second, 6);
    expect(await _text(target), 'firstsecond');
    expect(source.isClosedForRead, isTrue);
  });

  test(
    'finds a delimiter split by its arrival',
    () => runTest((it) async {
      final ByteChannel source = arrivingText(it, ['part-', '-', 'a', 'brest']);
      final target = ByteChannel();

      final int copied = await source.readUntil(_boundary, target);
      target.close();

      expect(copied, 4);
      expect(await _text(target), 'part');
      expect(utf8.decode(await source.toBytes()), 'rest');
    }),
  );

  test('falls back to a shorter match after a partial one', () async {
    final source = ByteReadChannel.fromText('xababaababc');
    final target = ByteChannel();

    final int copied = await source.readUntil(
      'ababc'.encodeToByteString(),
      target,
    );
    target.close();

    expect(copied, 6);
    expect(await _text(target), 'xababa');
  });

  test('copies a byte that ends a partial match', () async {
    final source = ByteReadChannel.fromText('-x--ab');
    final target = ByteChannel();

    final int copied = await source.readUntil(_boundary, target);
    target.close();

    expect(copied, 2);
    expect(await _text(target), '-x');
  });

  test('fails when the channel ends without the delimiter', () async {
    await expectLater(
      ByteReadChannel.fromText('no delimiter-')
          .readUntil(_boundary, ByteChannel()),
      throwsA(
        isA<IoException>().having(
          (error) => error.message,
          'message',
          'Expected "--ab" but encountered end of input',
        ),
      ),
    );
  });

  test('copies the rest with a partial match when told to', () async {
    final source = ByteReadChannel.fromText('rest--a');
    final target = ByteChannel();

    final int copied = await source.readUntil(
      _boundary,
      target,
      ignoreMissing: true,
    );
    target.close();

    expect(copied, 7);
    expect(await _text(target), 'rest--a');
  });

  test('fails beyond the limit', () async {
    await expectLater(
      ByteReadChannel.fromText('toolong--ab')
          .readUntil(_boundary, ByteChannel(), limit: 3),
      throwsA(
        isA<IoException>().having(
          (error) => error.message,
          'message',
          'Limit of 3 bytes exceeded while searching for "--ab"',
        ),
      ),
    );
    await expectLater(
      ByteReadChannel.fromText('ab--x--ab')
          .readUntil(_boundary, ByteChannel(), limit: 3),
      throwsA(isA<IoException>()),
    );
    await expectLater(
      ByteReadChannel.fromText('nothing')
          .readUntil(_boundary, ByteChannel(), limit: 3),
      throwsA(isA<IoException>()),
    );
  });

  test('escapes the line feeds of the delimiter in a message', () async {
    await expectLater(
      ByteReadChannel.fromText('x')
          .readUntil('\r\n'.encodeToByteString(), ByteChannel()),
      throwsA(
        isA<IoException>().having(
          (error) => error.message,
          'message',
          r'Expected "\r\n" but encountered end of input',
        ),
      ),
    );
  });

  test('flushes along the way to a writer that flushes every write', () async {
    final source = ByteReadChannel.fromText('abc--ab');
    final target = ByteChannel(autoFlush: true);

    await source.readUntil(_boundary, target);

    expect(target.availableForRead, 3);
  });

  test('refuses an empty delimiter', () {
    expect(
      () =>
          ByteReadChannel.fromText('x')
              .readUntil(ByteString.empty, ByteChannel()),
      throwsArgumentError,
    );
  });
}
