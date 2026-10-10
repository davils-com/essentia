/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/text/internal/unicode_normalization_data.dart';
import 'package:essentia/src/text/unicode_normalization.dart';
import 'package:test/test.dart';

import 'unicode_normalization_corpus.dart';

/// Reads a field of the corpus, a sequence of hexadecimal code points.
///
/// Returns the text, [previous] for an empty field.
String _text(String field, String previous) => field.isEmpty
    ? previous
    : String.fromCharCodes(
        field.split(',').map((codePoint) => int.parse(codePoint, radix: 16)),
      );

/// Reads every case of [unicodeNormalizationCorpus].
///
/// Returns the cases in their order: the source, its NFC and its NFD.
List<({String source, String nfc, String nfd})> _cases() =>
    unicodeNormalizationCorpus.split('|').map((line) {
      final List<String> fields = line.split(';');
      final String source = _text(fields[0], '');
      final String nfc = _text(fields[1], source);
      return (source: source, nfc: nfc, nfd: _text(fields[2], nfc));
    }).toList();

/// Writes [text] as its code points, for a readable failure.
///
/// Returns the code points in hexadecimal.
String _codePoints(String text) =>
    text.runes.map((codePoint) => codePoint.toRadixString(16)).join(' ');

/// Covers NFC, NFD and the NFC check, by hand and against the generated
/// corpus.
void main() {
  test('composes a letter and a combining mark', () {
    final String composed = 'ü'.toNfc();

    expect(composed, 'ü');
  });

  test('decomposes a precomposed letter', () {
    final String decomposed = 'ü'.toNfd();

    expect(decomposed, 'ü');
  });

  test('returns text below the combining marks as the same instance', () {
    final text = String.fromCharCodes('Grüße, World!'.codeUnits);

    final String composed = text.toNfc();

    expect(identical(composed, text), isTrue);
  });

  test('returns NFC text with marks as the same instance', () {
    final text = String.fromCharCodes('café ḉ 가 中'.runes);

    final String composed = text.toNfc();

    expect(identical(composed, text), isTrue);
  });

  test('returns NFC text that only may combine as the same instance', () {
    final text = String.fromCharCodes('x́'.runes);

    final String composed = text.toNfc();

    expect(identical(composed, text), isTrue);
  });

  test('returns NFD text as the same instance', () {
    final text = String.fromCharCodes('café 가'.runes);

    final String decomposed = text.toNfd();

    expect(identical(decomposed, text), isTrue);
  });

  test('returns ASCII text in NFD as the same instance', () {
    final text = String.fromCharCodes('plain text'.codeUnits);

    final String decomposed = text.toNfd();

    expect(identical(decomposed, text), isTrue);
  });

  test('composes Hangul jamo into a syllable', () {
    final String syllable = '가'.toNfc();

    expect(syllable, '가');
  });

  test('composes a syllable and a trailing consonant', () {
    final String syllable = '각'.toNfc();

    expect(syllable, '각');
  });

  test('decomposes a Hangul syllable with a trailing consonant', () {
    final String jamo = '힣'.toNfd();

    expect(jamo, '힣');
  });

  test('keeps a syllable with a trailing consonant apart from another', () {
    final String text = '각ᆨ'.toNfc();

    expect(text, '각ᆨ');
  });

  test('decomposes a supplementary character into surrogate pairs', () {
    final String decomposed = '\u{1D15E}'.toNfd();

    expect(decomposed, '\u{1D157}\u{1D165}');
  });

  test('keeps a supplementary composition exclusion decomposed', () {
    final String composed = '\u{1D15E}'.toNfc();

    expect(composed, '\u{1D157}\u{1D165}');
  });

  test('composes a supplementary pair', () {
    final String composed = '\u{11099}\u{110BA}'.toNfc();

    expect(composed, '\u{1109A}');
  });

  test('keeps a composition exclusion decomposed', () {
    final String composed = 'क़'.toNfc();

    expect(composed, 'क़');
  });

  test('maps a singleton to its canonical equivalent', () {
    final String composed = 'Å'.toNfc();

    expect(composed, 'Å');
  });

  test('decomposes a non-starter decomposition', () {
    final String composed = '̈́'.toNfc();

    expect(composed, '̈́');
  });

  test('reorders marks before composing', () {
    final String composed = 'ą́'.toNfc();

    expect(composed, 'ą́');
  });

  test('composes canonically equivalent sequences alike', () {
    final String ogonekFirst = 'ą́'.toNfc();
    final String acuteFirst = 'ą́'.toNfc();

    expect(ogonekFirst, acuteFirst);
  });

  test('keeps a mark blocked by one of the same class', () {
    final String composed = 'e̅́'.toNfc();

    expect(composed, 'e̅́');
  });

  test('keeps the order of marks of the same class', () {
    final String decomposed = 'á̀'.toNfd();

    expect(decomposed, 'á̀');
  });

  test('composes two adjacent starters', () {
    final String composed = 'ୋ'.toNfc();

    expect(composed, 'ୋ');
  });

  test('keeps a lone surrogate', () {
    final String composed = '\uD800é\uDC00'.toNfc();

    expect(composed, '\uD800é\uDC00');
  });

  test('keeps leading combining marks', () {
    final String composed = '̨́a'.toNfc();

    expect(composed, '̨́a');
  });

  test('normalizes empty text', () {
    expect(''.toNfc(), '');
    expect(''.toNfd(), '');
    expect(''.isNfc, isTrue);
  });

  test('tells NFC text from other text', () {
    expect('ü'.isNfc, isTrue);
    expect('x́'.isNfc, isTrue);
    expect('ü'.isNfc, isFalse);
    expect('Å'.isNfc, isFalse);
    expect('ą́'.isNfc, isFalse);
    expect('가'.isNfc, isFalse);
  });

  test('uses the character data of Unicode 16.0.0', () {
    expect(unicodeNormalizationVersion, '16.0.0');
  });

  group('the generated corpus', () {
    final List<({String source, String nfc, String nfd})> cases = _cases();

    test('has every case', () {
      expect(cases, hasLength(unicodeNormalizationCorpusSize));
    });

    test('brings every case into NFC', () {
      for (final (:source, :nfc, :nfd) in cases) {
        expect(source.toNfc(), nfc, reason: _codePoints(source));
        expect(nfd.toNfc(), nfc, reason: _codePoints(nfd));
      }
    });

    test('brings every case into NFD', () {
      for (final (:source, :nfc, :nfd) in cases) {
        expect(source.toNfd(), nfd, reason: _codePoints(source));
        expect(nfc.toNfd(), nfd, reason: _codePoints(nfc));
      }
    });

    test('tells NFC from other text in every case', () {
      for (final (:source, :nfc, :nfd) in cases) {
        expect(source.isNfc, source == nfc, reason: _codePoints(source));
        expect(nfc.isNfc, isTrue, reason: _codePoints(nfc));
        expect(nfd.isNfc, nfd == nfc, reason: _codePoints(nfd));
      }
    });
  });
}
