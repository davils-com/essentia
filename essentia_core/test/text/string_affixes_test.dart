/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/text/string_affixes.dart';
import 'package:test/test.dart';

/// Covers removing prefixes, suffixes and surroundings, and common affixes.
void main() {
  test('removes a present prefix', () {
    const text = 'unhappy';

    final String rest = text.removePrefix('un');

    expect(rest, 'happy');
  });

  test('keeps the text when the prefix is missing', () {
    const text = 'happy';

    final String rest = text.removePrefix('un');

    expect(rest, 'happy');
  });

  test('removes a present suffix', () {
    const text = 'file.txt';

    final String rest = text.removeSuffix('.txt');

    expect(rest, 'file');
  });

  test('keeps the text when the suffix is missing', () {
    const text = 'file';

    final String rest = text.removeSuffix('.txt');

    expect(rest, 'file');
  });

  test('removes the same delimiter from both ends', () {
    const text = '"quoted"';

    final String rest = text.removeSurrounding('"');

    expect(rest, 'quoted');
  });

  test('removes different delimiters from both ends', () {
    const text = '<tag>';

    final String rest = text.removeSurrounding('<', '>');

    expect(rest, 'tag');
  });

  test('keeps the text when only one end carries the delimiter', () {
    const text = '<tag';

    final String rest = text.removeSurrounding('<', '>');

    expect(rest, '<tag');
  });

  test('keeps the text when the delimiters overlap', () {
    const text = '"';

    final String rest = text.removeSurrounding('"');

    expect(rest, '"');
  });

  test('finds the common prefix', () {
    const text = 'interstellar';

    final String prefix = text.commonPrefixWith('internet');

    expect(prefix, 'inter');
  });

  test('never ends a common prefix inside a surrogate pair', () {
    const text = 'a😀';

    final String prefix = text.commonPrefixWith('a😁');

    expect(prefix, 'a');
  });

  test('never ends a common prefix inside a surrogate pair of the other', () {
    const text = 'a\uD83D';

    final String prefix = text.commonPrefixWith('a😀');

    expect(prefix, 'a');
  });

  test('finds the common suffix', () {
    const text = 'walking';

    final String suffix = text.commonSuffixWith('talking');

    expect(suffix, 'alking');
  });

  test('never starts a common suffix inside a surrogate pair', () {
    const text = '😀b';

    final String suffix = text.commonSuffixWith('😈b');

    expect(suffix, 'b');
  });

  test('never starts a common suffix inside a surrogate pair of the other', () {
    const text = '\uDE00b';

    final String suffix = text.commonSuffixWith('😀b');

    expect(suffix, 'b');
  });

  test('finds no common prefix between unrelated texts', () {
    const text = 'abc';

    final String prefix = text.commonPrefixWith('xyz');

    expect(prefix, '');
  });
}
