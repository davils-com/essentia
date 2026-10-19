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

import 'package:essentia_coroutines/testing.dart';
import 'package:essentia_io/essentia_io.dart';
import 'package:test/test.dart';

import '../support/arriving_channel.dart';

/// Reads every line of [channel] with [read].
///
/// Returns the lines.
Future<List<String>> _lines(
  ByteReadChannel channel,
  Future<String?> Function(ByteReadChannel channel) read,
) async {
  final lines = <String>[];
  for (
    String? line = await read(channel);
    line != null;
    line = await read(channel)
  ) {
    lines.add(line);
  }
  return lines;
}

/// Covers reading lines: the endings, lines split by their arrival, the
/// limit and the last line.
void main() {
  test('ends a line at LF and at CR LF', () async {
    final channel = ByteReadChannel.fromText('one\ntwo\r\n\nthree');

    final List<String> lines = await _lines(channel, (it) => it.readLine());

    expect(lines, ['one', 'two', '', 'three']);
  });

  test(
    'keeps a CR alone by default and ends the line there when lenient',
    () async {
      final List<String> strict = await _lines(
        ByteReadChannel.fromText('a\rb\nc\r'),
        (it) => it.readLine(),
      );
      final List<String> lenient = await _lines(
        ByteReadChannel.fromText('a\rb\nc\r\rd'),
        (it) => it.readLine(lineEnding: LineEnding.lenient),
      );

      expect(strict, ['a\rb', 'c\r']);
      expect(lenient, ['a', 'b', 'c', '', 'd']);
    },
  );

  test(
    'reads lines split anywhere by their arrival',
    () => runTest((it) async {
      final ByteChannel channel = arrivingText(it, [
        'fir',
        'st\r',
        '\nsec',
        'ond\n',
        'üb',
        'er\r\n',
      ]);

      final List<String> lines = await _lines(channel, (it) => it.readLine());

      expect(lines, ['first', 'second', 'über']);
    }),
  );

  test(
    'decodes a character split by its arrival',
    () => runTest((it) async {
      final ByteChannel channel = arrivingChannel(it, [
        [0x61, 0xC3],
        [0xBC, 0x0A],
      ]);

      expect(await channel.readLine(), 'aü');
    }),
  );

  test(
    'ends a lenient line at a CR that arrives last',
    () => runTest((it) async {
      final ByteChannel channel = arrivingText(it, [
        'one\r',
        'two\n',
        'three\r',
      ]);

      final List<String> lines = await _lines(
        channel,
        (it) => it.readLine(lineEnding: LineEnding.lenient),
      );

      expect(lines, ['one', 'two', 'three']);
    }),
  );

  test(
    'keeps a CR that arrives last when no LF follows',
    () => runTest((it) async {
      final ByteChannel channel = arrivingText(it, ['one\r', 'two\n']);

      expect(await channel.readLine(), 'one\rtwo');
    }),
  );

  test('counts the bytes of a line into a sink', () async {
    final channel = ByteReadChannel.fromText('héllo\n');
    final out = StringBuffer();

    final int read = await channel.readLineTo(out);
    final int end = await channel.readLineTo(out);

    expect(read, 6);
    expect(end, -1);
    expect(out.toString(), 'héllo');
  });

  test(
    'reads a strict line up to its limit, its ending right behind it',
    () async {
      final List<String> lines = await _lines(
        ByteReadChannel.fromText('abc\nde\r\nf\n'),
        (it) => it.readLineStrict(limit: 3),
      );

      expect(lines, ['abc', 'de', 'f']);
    },
  );

  test('ends a lenient strict line at a CR right behind its limit', () async {
    final channel = ByteReadChannel.fromText('abc\rd\n');

    final String? line = await channel.readLineStrict(
      limit: 3,
      lineEnding: LineEnding.lenient,
    );

    expect(line, 'abc');
    expect(await channel.readLineStrict(), 'd');
  });

  test('refuses a strict line longer than its limit', () async {
    await expectLater(
      ByteReadChannel.fromText('abcd\n').readLineStrict(limit: 3),
      throwsA(
        isA<TooLongLineException>().having(
          (error) => error.message,
          'message',
          'Line exceeds limit of 3 bytes',
        ),
      ),
    );
    await expectLater(
      ByteReadChannel.fromText('abc\rx').readLineStrict(limit: 3),
      throwsA(isA<TooLongLineException>()),
    );
  });

  test('refuses a strict last line without an ending', () async {
    await expectLater(
      ByteReadChannel.fromText('abc').readLineStrict(),
      throwsA(
        isA<EofException>().having(
          (error) => error.message,
          'message',
          'Unexpected end of stream after reading 3 bytes',
        ),
      ),
    );
    await expectLater(
      ByteReadChannel.fromText('abc').readLineStrict(limit: 3),
      throwsA(isA<EofException>()),
    );
  });

  test('hands the part of a refused line to the sink', () async {
    final out = StringBuffer();

    await expectLater(
      ByteReadChannel.fromText('abcdef').readLineStrictTo(out, limit: 4),
      throwsA(isA<TooLongLineException>()),
    );

    expect(out.toString(), 'abcd');
  });

  test('refuses a negative limit', () {
    expect(
      () => ByteReadChannel.fromText('a').readLineStrict(limit: -1),
      throwsRangeError,
    );
  });

  test('reads nothing from a channel that ended', () async {
    expect(await ByteReadChannel.empty.readLineStrict(), isNull);
  });
}
