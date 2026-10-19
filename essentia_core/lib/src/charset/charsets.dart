/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:convert';

import 'package:essentia_core/src/charset/charset.dart';
import 'package:essentia_core/src/charset/internal/built_charset.dart';
import 'package:essentia_core/src/charset/internal/decoding_converter.dart';
import 'package:essentia_core/src/charset/internal/encoding_converter.dart';
import 'package:essentia_core/src/charset/internal/utf16_decoding.dart';
import 'package:essentia_core/src/charset/internal/utf16_encoding.dart';
import 'package:essentia_core/src/charset/internal/windows1252_decoding.dart';
import 'package:essentia_core/src/charset/internal/windows1252_encoding.dart';

/// The charsets Essentia supports.
abstract final class Charsets {
  /// UTF-8, RFC 3629, the charset of the web: every character, one to four
  /// bytes each.
  static const Charset utf8 = BuiltCharset(
    'UTF-8',
    <String>['UTF8', 'unicode-1-1-utf-8'],
    Utf8Encoder(),
    Utf8Decoder(allowMalformed: true),
  );

  /// US-ASCII, the characters U+0000 to U+007F, one byte each.
  static const Charset usAscii = BuiltCharset(
    'US-ASCII',
    <String>[
      'ASCII',
      'ANSI_X3.4-1968',
      'ANSI_X3.4-1986',
      'iso-ir-6',
      'ISO_646.irv:1991',
      'ISO646-US',
      'us',
      'IBM367',
      'cp367',
      'csASCII',
      '646',
    ],
    AsciiEncoder(),
    AsciiDecoder(allowInvalid: true),
  );

  /// ISO-8859-1, Latin-1, the characters U+0000 to U+00FF, one byte each:
  /// the charset of HTTP/1.1 header values.
  static const Charset iso88591 = BuiltCharset(
    'ISO-8859-1',
    <String>[
      'ISO_8859-1:1987',
      'ISO_8859-1',
      'ISO8859-1',
      'ISO8859_1',
      '8859_1',
      'iso-ir-100',
      'latin1',
      'l1',
      'IBM819',
      'CP819',
      '819',
      'csISOLatin1',
    ],
    Latin1Encoder(),
    Latin1Decoder(allowInvalid: true),
  );

  /// windows-1252, Latin-1 with printable characters such as `€` in place
  /// of the C1 controls from 0x80 to 0x9F; the five bytes it leaves
  /// undefined decode to the C1 controls, as in the WHATWG encoding
  /// standard.
  static const Charset windows1252 = BuiltCharset(
    'windows-1252',
    <String>['cp1252', 'x-cp1252', 'ibm-1252', 'ibm1252'],
    EncodingConverter(Windows1252Encoding.new),
    DecodingConverter(Windows1252Decoding.new),
  );

  /// UTF-16 with a byte order mark: decoding follows the mark and reads
  /// big-endian without one, encoding writes the big-endian mark first.
  static const Charset utf16 = BuiltCharset(
    'UTF-16',
    <String>['UTF_16', 'utf16', 'unicode', 'UnicodeBig'],
    EncodingConverter(Utf16Encoding.marked),
    DecodingConverter(Utf16Decoding.marked),
  );

  /// UTF-16 big-endian, without a byte order mark: a leading U+FEFF is a
  /// character like any other.
  static const Charset utf16be = BuiltCharset(
    'UTF-16BE',
    <String>['UTF_16BE', 'X-UTF-16BE', 'ISO-10646-UCS-2', 'UnicodeBigUnmarked'],
    EncodingConverter(Utf16Encoding.bigEndian),
    DecodingConverter(Utf16Decoding.bigEndian),
  );

  /// UTF-16 little-endian, without a byte order mark: a leading U+FEFF is
  /// a character like any other.
  static const Charset utf16le = BuiltCharset(
    'UTF-16LE',
    <String>['UTF_16LE', 'X-UTF-16LE', 'UnicodeLittleUnmarked'],
    EncodingConverter(Utf16Encoding.littleEndian),
    DecodingConverter(Utf16Decoding.littleEndian),
  );
}
