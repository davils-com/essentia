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

import 'package:essentia_core/essentia_core.dart';
import 'package:test/test.dart';

/// Patterns and texts on which a `LinearRegExp` must answer as a `RegExp`
/// in its unicode mode does.
const _agreements = <String, List<String>>{
  'abc': <String>['abc', 'xabcx', 'ab', ''],
  r'^abc$': <String>['abc', 'abcd', ' abc'],
  'a|b|c': <String>['a', 'b', 'c', 'd', ''],
  'ab*c': <String>['ac', 'abc', 'abbbbc', 'abd'],
  'ab+c': <String>['ac', 'abc', 'abbc'],
  'ab?c': <String>['ac', 'abc', 'abbc'],
  r'^a{3}$': <String>['aa', 'aaa', 'aaaa'],
  r'^a{2,}$': <String>['a', 'aa', 'aaaaa'],
  r'^a{2,4}$': <String>['a', 'aa', 'aaaa', 'aaaaa'],
  r'^a{0}$': <String>['', 'a'],
  r'^(ab)+$': <String>['ab', 'abab', 'aba', ''],
  r'^(?:ab|cd)*$': <String>['', 'ab', 'abcd', 'cdab', 'abc'],
  r'^(?<word>[a-z]+)-(?:\d+)$': <String>['ab-12', 'ab-', '-12', 'AB-12'],
  r'^a*?b+?$': <String>['b', 'aab', 'aa'],
  '.': <String>['x', '', '\n', '\u{1F600}'],
  r'^.$': <String>['\u{1F600}', 'ab', '\r'],
  r'^[a-c]+$': <String>['abc', 'abd', ''],
  r'^[^a-c]+$': <String>['xyz', 'xaz'],
  r'^[-a]$': <String>['-', 'a', 'b'],
  r'^[a-]$': <String>['-', 'a'],
  r'^[\d\s]+$': <String>['1 2', '1a'],
  r'^[^\d]+$': <String>['ab', 'a1'],
  r'^\d+$': <String>['0123', '12a', ''],
  r'^\D+$': <String>['ab', 'a1'],
  r'^\w+$': <String>['a_1', 'a-1', 'ä'],
  r'^\W+$': <String>['--', 'a-'],
  r'^\s+$': <String>[' \t\n', ' 　', 'a'],
  r'^\S+$': <String>['ab', 'a b'],
  r'\bfoo\b': <String>['foo', 'a foo b', 'foobar', 'barfoo'],
  r'\Bfoo': <String>['afoo', 'foo'],
  r'^\p{L}+$': <String>['abc', 'äöü', 'Ωμέγα', 'a1'],
  r'^\P{L}+$': <String>['123', '1a'],
  r'^[\p{Lu}\d]+$': <String>['AB12', 'Ab'],
  r'^\p{Script=Greek}+$': <String>['Ωμέγα', 'abc'],
  r'^\u0041\x42\u{43}$': <String>['ABC', 'abc'],
  r'^\uD83D\uDE00$': <String>['\u{1F600}', 'x'],
  r'^[\u{1F600}-\u{1F64F}]+$': <String>['\u{1F600}\u{1F64F}', 'a'],
  r'^\t\n\v\f\r\0$': <String>['\t\n\v\f\r\u0000', 'x'],
  r'^\cJ$': <String>['\n', 'J'],
  r'^\.\*\+\?\(\)\[\]\{\}\|\^\$\\\/$': <String>[r'.*+?()[]{}|^$\/', 'x'],
  r'^[\b]$': <String>['\b', 'b'],
  r'^[\-]$': <String>['-', 'x'],
  '(a*)*b': <String>['aaab', 'aaa'],
  '(|a)+c': <String>['ac', 'c', 'b'],
  r'^(a|ab)(c|bcd)(d*)$': <String>['abcd', 'abcdd', 'abc'],
  r'^$': <String>['', 'a'],
  '': <String>['', 'a'],
  r'^[]$': <String>['', 'a'],
  r'^[^]$': <String>['a', '\n', ''],
};

/// Covers matching in linear time and the patterns it refuses.
void main() {
  group('matching', () {
    for (final MapEntry<String, List<String>>(key: pattern, value: texts)
        in _agreements.entries) {
      test('answers as RegExp does for $pattern', () {
        final linear = LinearRegExp(pattern);
        final backtracking = RegExp(pattern, unicode: true);
        for (final text in texts) {
          expect(
            linear.hasMatch(text),
            backtracking.hasMatch(text),
            reason: 'on ${text.runes.toList()}',
          );
        }
      });
    }

    test('matches what makes a backtracking expression take forever', () {
      final pattern = LinearRegExp(r'^(a+)+$');
      final text = '${'a' * 20000}b';

      expect(pattern.hasMatch(text), isFalse);
      expect(pattern.hasMatch('a' * 20000), isTrue);
    });

    test('matches nested alternatives that overlap in linear time', () {
      final pattern = LinearRegExp(r'^(a|aa|a?a)*c$');

      expect(pattern.hasMatch('${'a' * 20000}b'), isFalse);
    });

    test('keeps the pattern and counts its instructions', () {
      final pattern = LinearRegExp('ab');

      expect(pattern.pattern, 'ab');
      expect(pattern.instructionCount, 3);
      expect(pattern.toString(), 'LinearRegExp(ab)');
    });
  });

  group('refusals', () {
    /// Expects [pattern] to be refused for [failure] at [offset].
    void refuses(String pattern, LinearRegExpFailure failure, [int? offset]) {
      expect(
        () => LinearRegExp(pattern),
        throwsA(
          isA<LinearRegExpException>()
              .having((it) => it.failure, 'failure', failure)
              .having((it) => it.offset, 'offset', offset ?? isNonNegative),
        ),
      );
    }

    test('refuses a backreference and a named one', () {
      refuses(r'(a)\1', LinearRegExpFailure.unsupported, 3);
      refuses(r'(?<x>a)\k<x>', LinearRegExpFailure.unsupported);
    });

    test('refuses every lookaround', () {
      for (final pattern in <String>['(?=a)', '(?!a)', '(?<=a)', '(?<!a)']) {
        refuses(pattern, LinearRegExpFailure.unsupported, 0);
      }
    });

    test('refuses what is no pattern of the unicode mode', () {
      for (final pattern in <String>[
        '(',
        ')',
        'a)',
        '[a',
        '*',
        'a**',
        '+a',
        '{',
        'a{',
        'a{1',
        'a{1,',
        'a{,2}',
        'a{2,1}',
        '}',
        ']',
        r'\',
        r'\q',
        r'\c1',
        r'\x4',
        r'\u12',
        r'\u{110000}',
        r'\u{}',
        r'\01',
        r'\p{Unknown}',
        r'\p{L',
        r'\pL',
        '[b-a]',
        r'[\d-z]',
        r'[a-\d]',
        r'[\1]',
        '(?x)',
        '(?<1a>x)',
        '(?<>x)',
        r'[\',
        '^*',
      ]) {
        refuses(pattern, LinearRegExpFailure.syntax);
      }
    });

    test('refuses a pattern of too many instructions', () {
      refuses('a{3000}', LinearRegExpFailure.tooComplex, 0);
      refuses('(a{100}){100}', LinearRegExpFailure.tooComplex);
      expect(
        LinearRegExp('a{3000}', maxInstructions: 4000).hasMatch('a'),
        isFalse,
      );
    });

    test('names the offset in code units past a surrogate pair', () {
      refuses('\u{1F600}(', LinearRegExpFailure.syntax, 2);
    });

    test('never quotes the pattern in its message', () {
      expect(
        () => LinearRegExp('secret(?=x)'),
        throwsA(
          isA<LinearRegExpException>().having(
            (it) => it.toString(),
            'message',
            allOf(
              contains('unsupported at offset 6'),
              isNot(contains('secret')),
            ),
          ),
        ),
      );
    });

    test('refuses a bound of no instructions', () {
      expect(() => LinearRegExp('a', maxInstructions: 0), throwsArgumentError);
    });
  });
}
