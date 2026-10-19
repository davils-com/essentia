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

import 'package:essentia_core/src/collection/window_remainder.dart';
import 'package:essentia_core/src/text/string_slicing.dart';
import 'package:test/test.dart';

/// A file name with several dots.
const _file = 'some.file.name.txt';

/// A text with a surrogate pair between two letters.
const _emoji = 'a😀b';

/// Covers the substring, take, drop, chunk and window operations on text.
void main() {
  test('cuts before the first delimiter', () {
    final String head = _file.substringBefore('.');

    expect(head, 'some');
  });

  test('cuts after the first delimiter', () {
    final String tail = _file.substringAfter('.');

    expect(tail, 'file.name.txt');
  });

  test('cuts before the last delimiter', () {
    final String head = _file.substringBeforeLast('.');

    expect(head, 'some.file.name');
  });

  test('cuts after the last delimiter', () {
    final String tail = _file.substringAfterLast('.');

    expect(tail, 'txt');
  });

  test('keeps the whole text when the delimiter is missing', () {
    final String head = _file.substringBefore('/');

    expect(head, _file);
  });

  test('uses the given text when the delimiter is missing', () {
    final String tail = _file.substringAfterLast('/', whenMissing: '');

    expect(tail, '');
  });

  test('takes the first code units', () {
    final String head = _file.take(4);

    expect(head, 'some');
  });

  test('takes the whole text when more is requested than exists', () {
    const text = 'ab';

    final String head = text.take(5);

    expect(head, 'ab');
  });

  test('refuses a negative count to take', () {
    String take() => _file.take(-1);

    expect(take, throwsRangeError);
  });

  test('drops the first code units', () {
    final String tail = _file.drop(15);

    expect(tail, 'txt');
  });

  test('takes the last code units', () {
    final String tail = _file.takeLast(3);

    expect(tail, 'txt');
  });

  test('drops the last code units', () {
    final String head = _file.dropLast(4);

    expect(head, 'some.file.name');
  });

  test('drops everything when more is dropped than exists', () {
    const text = 'ab';

    final String head = text.dropLast(5);

    expect(head, '');
  });

  test('takes the leading characters that match', () {
    const text = '123abc';

    final String digits = text.takeWhile(
      (character) => '0123456789'.contains(character),
    );

    expect(digits, '123');
  });

  test('takes the whole text when every character matches', () {
    const text = '123';

    final String digits = text.takeWhile((character) => character != 'x');

    expect(digits, '123');
  });

  test('drops the leading characters that match', () {
    const text = '123abc';

    final String rest = text.dropWhile(
      (character) => '0123456789'.contains(character),
    );

    expect(rest, 'abc');
  });

  test('takes the trailing characters that match', () {
    const text = 'abc123';

    final String digits = text.takeLastWhile(
      (character) => '0123456789'.contains(character),
    );

    expect(digits, '123');
  });

  test('takes the whole text when every trailing character matches', () {
    const text = '123';

    final String digits = text.takeLastWhile((character) => character != 'x');

    expect(digits, '123');
  });

  test('drops the trailing characters that match', () {
    const text = 'abc123';

    final String rest = text.dropLastWhile(
      (character) => '0123456789'.contains(character),
    );

    expect(rest, 'abc');
  });

  test('never splits a surrogate pair while taking characters', () {
    final String head = _emoji.takeWhile((character) => character != 'b');

    expect(head, 'a😀');
  });

  test('hands a whole surrogate pair to the predicate', () {
    final String tail = _emoji.takeLastWhile((character) => character != 'a');

    expect(tail, '😀b');
  });

  test('cuts the text into chunks', () {
    const text = 'abcdefg';

    final List<String> chunks = text.chunked(3);

    expect(chunks, <String>['abc', 'def', 'g']);
  });

  test('slides a window over the text', () {
    const text = 'abcd';

    final List<String> windows = text.windowed(2);

    expect(windows, <String>['ab', 'bc', 'cd']);
  });

  test('keeps the partial windows over the text', () {
    const text = 'abcde';

    final List<String> windows = text.windowed(
      3,
      step: 2,
      remainder: WindowRemainder.keep,
    );

    expect(windows, <String>['abc', 'cde', 'e']);
  });

  test('refuses a window size that is not positive', () {
    List<String> slide() => _file.windowed(0);

    expect(slide, throwsRangeError);
  });

  test('refuses a chunk size that is not positive', () {
    List<String> chunk() => _file.chunked(-2);

    expect(chunk, throwsRangeError);
  });

  test('hands out windows that cannot be modified', () {
    final List<String> windows = _file.windowed(4);

    void modify() => windows.add('x');

    expect(modify, throwsUnsupportedError);
  });

  test('removes a range of code units', () {
    const text = 'abcdef';

    final String shortened = text.removeRange(1, 3);

    expect(shortened, 'adef');
  });
}
