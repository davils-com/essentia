/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';
import 'dart:convert';

import 'package:essentia_core/essentia_core.dart';
import 'package:test/test.dart';

import '../support/collecting_sink.dart';

/// Decodes [bytes] with [charset] in chunks of [size] bytes.
///
/// Returns the text.
Future<String> _decodeInChunks(Charset charset, List<int> bytes, int size) =>
    Stream<List<int>>.fromIterable([
      for (var start = 0; start < bytes.length; start += size)
        bytes.sublist(
          start,
          start + size > bytes.length ? bytes.length : start + size,
        ),
    ]).transform(charset.decoder).join();

/// Encodes [text] with [charset] in chunks of [size] code units.
///
/// Returns the bytes.
Future<List<int>> _encodeInChunks(
  Charset charset,
  String text,
  int size,
) async {
  final List<List<int>> chunks = await Stream<String>.fromIterable([
    for (var start = 0; start < text.length; start += size)
      text.substring(
        start,
        start + size > text.length ? text.length : start + size,
      ),
  ]).transform(charset.encoder).toList();
  return [for (final List<int> chunk in chunks) ...chunk];
}

/// Tests what each charset turns text and bytes into.
void main() {
  group('UTF-8', () {
    test('encodes and decodes every character', () {
      const text = 'a€😀';

      final List<int> bytes = Charsets.utf8.encode(text);

      expect(bytes, [0x61, 0xE2, 0x82, 0xAC, 0xF0, 0x9F, 0x98, 0x80]);
      expect(Charsets.utf8.decode(bytes), text);
    });

    test('replaces a malformed sequence', () {
      expect(Charsets.utf8.decode([0x61, 0xFF, 0x62]), 'a�b');
    });
  });

  group('US-ASCII', () {
    test('encodes ASCII and refuses anything else', () {
      expect(Charsets.usAscii.encode('Hi'), [0x48, 0x69]);
      expect(() => Charsets.usAscii.encode('é'), throwsArgumentError);
    });

    test('replaces a byte above 0x7F', () {
      expect(Charsets.usAscii.decode([0x41, 0x80]), 'A�');
    });
  });

  group('ISO-8859-1', () {
    test('maps every byte to the character of the same number', () {
      final List<int> bytes = [for (var byte = 0; byte < 256; byte++) byte];

      final String text = Charsets.iso88591.decode(bytes);

      expect(text.codeUnits, bytes);
      expect(Charsets.iso88591.encode(text), bytes);
    });

    test('refuses a character above U+00FF', () {
      expect(() => Charsets.iso88591.encode('€'), throwsArgumentError);
    });
  });

  group('windows-1252', () {
    test('decodes the printable characters of 0x80 to 0x9F', () {
      expect(Charsets.windows1252.decode([0x80, 0x93, 0x94, 0x9F]), '€“”Ÿ');
    });

    test('decodes the undefined bytes to their C1 controls', () {
      expect(
        Charsets.windows1252.decode([0x81, 0x8D, 0x8F, 0x90, 0x9D]).codeUnits,
        [0x81, 0x8D, 0x8F, 0x90, 0x9D],
      );
    });

    test('keeps Latin-1 outside 0x80 to 0x9F', () {
      expect(Charsets.windows1252.decode([0x41, 0xE9, 0xFF]), 'Aéÿ');
    });

    test('replaces a value that is no byte', () {
      expect(Charsets.windows1252.decode([0x41, 0x100, -1]), 'A��');
    });

    test('encodes every character it decodes back to its byte', () {
      final List<int> bytes = [for (var byte = 0; byte < 256; byte++) byte];

      final List<int> encoded = Charsets.windows1252.encode(
        Charsets.windows1252.decode(bytes),
      );

      expect(encoded, bytes);
    });

    test('refuses a character it has no byte for, naming its place', () {
      expect(
        () => Charsets.windows1252.encode('abĀ'),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.invalidValue, 'invalidValue', 2)
              .having((error) => error.message, 'message', contains('U+0100')),
        ),
      );
      expect(() => Charsets.windows1252.encode('\u0080'), throwsArgumentError);
    });

    test('decodes and encodes in chunks', () async {
      expect(
        await _decodeInChunks(Charsets.windows1252, [0x80, 0x41, 0x9F], 1),
        '€AŸ',
      );
      expect(await _encodeInChunks(Charsets.windows1252, '€AŸ', 2), [
        0x80,
        0x41,
        0x9F,
      ]);
    });
  });

  group('UTF-16', () {
    const text = 'A€😀';
    const bigEndian = [0x00, 0x41, 0x20, 0xAC, 0xD8, 0x3D, 0xDE, 0x00];
    const littleEndian = [0x41, 0x00, 0xAC, 0x20, 0x3D, 0xD8, 0x00, 0xDE];

    test('encodes big-endian after a byte order mark', () {
      expect(Charsets.utf16.encode(text), [0xFE, 0xFF, ...bigEndian]);
      expect(Charsets.utf16.encode(''), isEmpty);
    });

    test('decodes after the mark in its order, big-endian without', () {
      expect(Charsets.utf16.decode([0xFE, 0xFF, ...bigEndian]), text);
      expect(Charsets.utf16.decode([0xFF, 0xFE, ...littleEndian]), text);
      expect(Charsets.utf16.decode(bigEndian), text);
    });

    test('keeps a mark in the middle as a character', () {
      expect(Charsets.utf16.decode([0xFE, 0xFF, 0xFE, 0xFF]), '﻿');
    });

    test('encodes and decodes each fixed order without a mark', () {
      expect(Charsets.utf16be.encode(text), bigEndian);
      expect(Charsets.utf16le.encode(text), littleEndian);
      expect(Charsets.utf16be.decode(bigEndian), text);
      expect(Charsets.utf16le.decode(littleEndian), text);
    });

    test('reads a leading mark of a fixed order as a character', () {
      expect(Charsets.utf16be.decode([0xFE, 0xFF, 0x00, 0x41]), '﻿A');
    });

    test('replaces unpaired surrogates and a lone last byte', () {
      expect(Charsets.utf16be.decode([0xDC, 0x00, 0x00, 0x41]), '�A');
      expect(Charsets.utf16be.decode([0xD8, 0x3D, 0x00, 0x41]), '�A');
      expect(Charsets.utf16be.decode([0xD8, 0x3D]), '�');
      expect(Charsets.utf16be.decode([0x00, 0x41, 0x00]), 'A�');
    });

    test('encodes unpaired surrogates as replacement characters', () {
      expect(Charsets.utf16be.encode('\uDC00A'), [0xFF, 0xFD, 0x00, 0x41]);
      expect(Charsets.utf16be.encode('\uD83DA'), [0xFF, 0xFD, 0x00, 0x41]);
      expect(Charsets.utf16be.encode('\uD83D'), [0xFF, 0xFD]);
    });

    test('decodes chunks split inside a code unit and a pair', () async {
      final marked = <int>[0xFF, 0xFE, ...littleEndian];

      for (var size = 1; size <= marked.length; size++) {
        expect(
          await _decodeInChunks(Charsets.utf16, marked, size),
          text,
          reason: '$size',
        );
      }
    });

    test('encodes chunks split inside a pair', () async {
      for (var size = 1; size <= text.length; size++) {
        expect(await _encodeInChunks(Charsets.utf16, text, size), [
          0xFE,
          0xFF,
          ...bigEndian,
        ], reason: '$size');
      }
    });

    test('ends a chunked decoding with what is left', () async {
      final input = StreamController<List<int>>();
      final Future<String> text = input.stream
          .transform(Charsets.utf16be.decoder)
          .join();

      input
        ..add([0x00, 0x41, 0xD8])
        ..add([0x3D]);
      await input.close();

      expect(await text, 'A�');
    });

    test('ends a chunked encoding with what is left', () async {
      expect(await _encodeInChunks(Charsets.utf16be, 'A\uD83D', 1), [
        0x00,
        0x41,
        0xFF,
        0xFD,
      ]);
    });
  });

  test('converts slices through the chunked sinks', () {
    final decoded = <String>[];
    final encoded = <List<int>>[];
    final decoding = Charsets.windows1252.decoder.startChunkedConversion(
      CollectingSink<String>(decoded),
    ) as ByteConversionSink;
    final encoding = Charsets.utf16be.encoder.startChunkedConversion(
      CollectingSink<List<int>>(encoded),
    ) as StringConversionSink;

    decoding.addSlice([0x41, 0x80, 0x42], 1, 2, false);
    encoding.addSlice('xAy', 1, 2, false);
    expect(() => decoding.addSlice([1], 0, 2, false), throwsRangeError);
    expect(() => encoding.addSlice('a', 0, 2, false), throwsRangeError);
    decoding.close();
    encoding.close();

    expect(decoded, ['€']);
    expect(encoded, [
      [0x00, 0x41],
    ]);
  });

  test('ends a chunked conversion with the last slice', () {
    final decoded = <String>[];
    final collecting = CollectingSink<String>(decoded);

    (Charsets.utf16be.decoder.startChunkedConversion(
      collecting,
    ) as ByteConversionSink).addSlice([0x00, 0x41, 0xD8], 0, 3, true);

    expect(decoded, ['A', '\uFFFD']);
    expect(collecting.closed, isTrue);
  });
}
