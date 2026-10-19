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

import 'package:essentia_core/src/collection/iterable_windowing.dart';
import 'package:essentia_core/src/collection/window_remainder.dart';
import 'package:test/test.dart';

import 'probe_iterable.dart';

/// The numbers from one to ten, as a lazy source.
final _oneToTen = Iterable<int>.generate(10, (index) => index + 1);

/// Covers `windowed`, `zipWithNext`, `takeLast`, `dropLast`,
/// `takeLastWhile` and `dropLastWhile` for iterables.
void main() {
  test('slides a window one element at a time', () {
    const numbers = <int>[1, 2, 3, 4];

    final List<List<int>> windows = numbers.windowed(3).toList();

    expect(windows, <List<int>>[
      <int>[1, 2, 3],
      <int>[2, 3, 4],
    ]);
  });

  test('slides a window by the given step and drops the remainder', () {
    final List<List<int>> windows = _oneToTen.windowed(5, step: 3).toList();

    expect(windows, <List<int>>[
      <int>[1, 2, 3, 4, 5],
      <int>[4, 5, 6, 7, 8],
    ]);
  });

  test('keeps the partial windows when the remainder is kept', () {
    final List<List<int>> windows = _oneToTen
        .windowed(5, step: 3, remainder: WindowRemainder.keep)
        .toList();

    expect(windows, <List<int>>[
      <int>[1, 2, 3, 4, 5],
      <int>[4, 5, 6, 7, 8],
      <int>[7, 8, 9, 10],
      <int>[10],
    ]);
  });

  test('skips the elements between windows when the step exceeds the size', () {
    final List<List<int>> windows = _oneToTen
        .windowed(2, step: 4, remainder: WindowRemainder.keep)
        .toList();

    expect(windows, <List<int>>[
      <int>[1, 2],
      <int>[5, 6],
      <int>[9, 10],
    ]);
  });

  test('yields no window when the source is shorter than the size', () {
    const numbers = <int>[1, 2];

    final List<List<int>> windows = numbers.windowed(3).toList();

    expect(windows, isEmpty);
  });

  test('refuses a window size that is not positive', () {
    const numbers = <int>[1, 2];

    Iterable<List<int>> slide() => numbers.windowed(0);

    expect(slide, throwsRangeError);
  });

  test('refuses a step that is not positive', () {
    const numbers = <int>[1, 2];

    Iterable<List<int>> slide() => numbers.windowed(1, step: 0);

    expect(slide, throwsRangeError);
  });

  test('hands out windows that cannot be modified', () {
    const numbers = <int>[1, 2];
    final List<int> window = numbers.windowed(2).first;

    void modify() => window.add(3);

    expect(modify, throwsUnsupportedError);
  });

  test('does not iterate before a window is requested', () {
    final probe = ProbeIterable<int>(<int>[1, 2, 3]);

    final int iterations = probe.iterationsWhileBuilding(
      (source) => source.windowed(2),
    );

    expect(iterations, 0);
  });

  test('iterates its source once for all windows', () {
    final probe = ProbeIterable<int>(<int>[1, 2, 3]);

    final int iterations = probe.iterationsWhileConsuming(
      (source) => source.windowed(2),
    );

    expect(iterations, 1);
  });

  test('slides over an endless source', () {
    final List<List<int>> windows = naturals().windowed(2).take(2).toList();

    expect(windows, <List<int>>[
      <int>[0, 1],
      <int>[1, 2],
    ]);
  });

  test('pairs every element with its successor', () {
    const numbers = <int>[1, 2, 4];

    final List<(int, int)> pairs = numbers.zipWithNext().toList();

    expect(pairs, <(int, int)>[(1, 2), (2, 4)]);
  });

  test('pairs nothing when a single element exists', () {
    const numbers = <int>[1];

    final List<(int, int)> pairs = numbers.zipWithNext().toList();

    expect(pairs, isEmpty);
  });

  test('pairs nothing when the source is empty', () {
    const numbers = <int>[];

    final List<(int, int)> pairs = numbers.zipWithNext().toList();

    expect(pairs, isEmpty);
  });

  test('pairs the elements of an endless source', () {
    final List<(int, int)> pairs = naturals().zipWithNext().take(2).toList();

    expect(pairs, <(int, int)>[(0, 1), (1, 2)]);
  });

  test('takes the last elements', () {
    final List<int> tail = _oneToTen.takeLast(3);

    expect(tail, <int>[8, 9, 10]);
  });

  test('takes every element when more are requested than exist', () {
    const Iterable<int> numbers = <int>[1, 2];

    final List<int> tail = numbers.takeLast(5);

    expect(tail, <int>[1, 2]);
  });

  test('takes nothing when no elements are requested', () {
    const Iterable<int> numbers = <int>[1, 2];

    final List<int> tail = numbers.takeLast(0);

    expect(tail, isEmpty);
  });

  test('refuses a negative count to take', () {
    const Iterable<int> numbers = <int>[1, 2];

    List<int> take() => numbers.takeLast(-1);

    expect(take, throwsRangeError);
  });

  test('hands out a tail that cannot be modified', () {
    const Iterable<int> numbers = <int>[1, 2];
    final List<int> tail = numbers.takeLast(1);

    void modify() => tail.add(3);

    expect(modify, throwsUnsupportedError);
  });

  test('drops the last elements', () {
    final List<int> head = _oneToTen.dropLast(7).toList();

    expect(head, <int>[1, 2, 3]);
  });

  test('drops every element when more are dropped than exist', () {
    const Iterable<int> numbers = <int>[1, 2];

    final List<int> head = numbers.dropLast(5).toList();

    expect(head, isEmpty);
  });

  test('refuses a negative count to drop', () {
    const Iterable<int> numbers = <int>[1, 2];

    Iterable<int> drop() => numbers.dropLast(-1);

    expect(drop, throwsRangeError);
  });

  test('drops the last elements of an endless source lazily', () {
    final List<int> head = naturals().dropLast(2).take(3).toList();

    expect(head, <int>[0, 1, 2]);
  });

  test('takes the trailing elements that match', () {
    const Iterable<int> numbers = <int>[2, 1, 4, 6];

    final List<int> tail = numbers.takeLastWhile((number) => number.isEven);

    expect(tail, <int>[4, 6]);
  });

  test('takes nothing when the last element does not match', () {
    const Iterable<int> numbers = <int>[2, 4, 5];

    final List<int> tail = numbers.takeLastWhile((number) => number.isEven);

    expect(tail, isEmpty);
  });

  test('hands out trailing elements that cannot be modified', () {
    const Iterable<int> numbers = <int>[2];
    final List<int> tail = numbers.takeLastWhile((number) => number.isEven);

    void modify() => tail.add(3);

    expect(modify, throwsUnsupportedError);
  });

  test('drops the trailing elements that match', () {
    const Iterable<int> numbers = <int>[2, 1, 4, 6];

    final List<int> head = numbers
        .dropLastWhile((number) => number.isEven)
        .toList();

    expect(head, <int>[2, 1]);
  });

  test('drops everything when every element matches', () {
    const Iterable<int> numbers = <int>[2, 4];

    final List<int> head = numbers
        .dropLastWhile((number) => number.isEven)
        .toList();

    expect(head, isEmpty);
  });

  test('drops the trailing matches of an endless source lazily', () {
    final List<int> head = naturals()
        .dropLastWhile((number) => number.isEven)
        .take(3)
        .toList();

    expect(head, <int>[0, 1, 2]);
  });
}
