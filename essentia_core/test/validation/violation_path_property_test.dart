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

import 'dart:math';

import 'package:essentia_core/essentia_core.dart';
import 'package:test/test.dart';

import 'path_step.dart';

/// How many generated cases each property is checked against.
const _cases = 300;

/// The letters a generated name is drawn from.
const _letters = 'abcdefghijklmnopqrstuvwxyz';

/// The characters a generated key is drawn from.
const _alphanumerics =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

/// Draws a string of one to ten characters out of [alphabet].
String _text(Random random, String alphabet) {
  final int length = 1 + random.nextInt(10);
  return String.fromCharCodes(
    List<int>.generate(
      length,
      (_) => alphabet.codeUnitAt(random.nextInt(alphabet.length)),
    ),
  );
}

/// Draws one step of any kind.
PathStep _step(Random random) {
  final int kind = random.nextInt(3);
  if (kind == 0) {
    return NamedStep(_text(random, _letters));
  }
  if (kind == 1) {
    return IndexStep(random.nextInt(1000));
  }
  return KeyedStep(_text(random, _alphanumerics));
}

/// Draws between [min] and [max] steps.
List<PathStep> _steps(Random random, int min, int max) =>
    List<PathStep>.generate(
      min + random.nextInt(max - min + 1),
      (_) => _step(random),
    );

/// Builds the path [steps] describe, starting at the root.
ViolationPath _build(List<PathStep> steps) =>
    steps.fold(ViolationPath.root, (path, step) => step.appendTo(path));

/// Reads [rendered] back into the steps it was rendered from.
List<PathStep> _parse(String rendered) {
  final steps = <PathStep>[];
  var cursor = 0;
  while (cursor < rendered.length) {
    cursor = _readAt(rendered, cursor, steps);
  }
  return steps;
}

/// Reads the step starting at [cursor] of [rendered] into [into].
///
/// Returns the position after it.
int _readAt(String rendered, int cursor, List<PathStep> into) {
  if (rendered[cursor] == '.') {
    return cursor + 1;
  }
  if (rendered.startsWith('["', cursor)) {
    final int end = rendered.indexOf('"]', cursor + 2);
    into.add(KeyedStep(rendered.substring(cursor + 2, end)));
    return end + 2;
  }
  if (rendered[cursor] == '[') {
    final int end = rendered.indexOf(']', cursor);
    into.add(IndexStep(int.parse(rendered.substring(cursor + 1, end))));
    return end + 1;
  }
  var end = cursor;
  while (end < rendered.length &&
      rendered[end] != '.' &&
      rendered[end] != '[') {
    end++;
  }
  into.add(NamedStep(rendered.substring(cursor, end)));
  return end;
}

/// Covers the properties of a violation path in seeded random loops.
void main() {
  test('every segment that was appended is present, in the order it was '
      'appended', () {
    final random = Random(1);
    for (var round = 0; round < _cases; round++) {
      final List<PathStep> appended = _steps(random, 0, 8);
      final ViolationPath path = _build(appended);

      expect(path.segments, hasLength(appended.length), reason: '$path');
      expect(
        path.segments.map((segment) => segment.toString()).toList(),
        appended.map((step) => step.rendered).toList(),
        reason: '$path',
      );
    }
  });

  test('a path with no segments is the root and renders as nothing at '
      'all', () {
    expect(_build(<PathStep>[]), ViolationPath.root);
    expect(ViolationPath.root.isRoot, isTrue);
    expect(ViolationPath.root.toString(), isEmpty);
  });

  test('a path with any segment at all is not the root', () {
    final random = Random(2);
    for (var round = 0; round < _cases; round++) {
      expect(_build(_steps(random, 1, 8)).isRoot, isFalse);
    }
  });

  test('the rendered path reads back as the segments that went into it', () {
    final random = Random(3);
    for (var round = 0; round < _cases; round++) {
      final List<PathStep> appended = _steps(random, 0, 8);
      final rendered = _build(appended).toString();

      expect(_parse(rendered), appended, reason: rendered);
    }
  });

  test('the rendering never leads with a separator or doubles one', () {
    final random = Random(4);
    for (var round = 0; round < _cases; round++) {
      final rendered = _build(_steps(random, 0, 8)).toString();

      expect(rendered, isNot(startsWith('.')), reason: rendered);
      expect(rendered, isNot(contains('..')), reason: rendered);
      expect(rendered, isNot(contains('.[')), reason: rendered);
    }
  });

  test('appending a whole path is appending its segments', () {
    final random = Random(5);
    for (var round = 0; round < _cases; round++) {
      final List<PathStep> outer = _steps(random, 0, 5);
      final List<PathStep> inner = _steps(random, 0, 5);
      final ViolationPath combined = _build(outer) + _build(inner);

      expect(combined, _build(<PathStep>[...outer, ...inner]));
      expect(_parse(combined.toString()), <PathStep>[...outer, ...inner]);
    }
  });

  test('equal paths built independently agree on their hash', () {
    final random = Random(6);
    for (var round = 0; round < _cases; round++) {
      final List<PathStep> appended = _steps(random, 0, 8);

      expect(_build(appended).hashCode, _build(appended).hashCode);
    }
  });
}
