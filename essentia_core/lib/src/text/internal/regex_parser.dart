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

import 'package:essentia_core/src/text/internal/code_point_class.dart';
import 'package:essentia_core/src/text/internal/regex_node.dart';
import 'package:essentia_core/src/text/linear_reg_exp_exception.dart';
import 'package:essentia_core/src/text/linear_reg_exp_failure.dart';
import 'package:meta/meta.dart';

/// Reads a pattern of ECMAScript in its unicode mode into [RegexNode]s,
/// refusing what is no pattern and what cannot be matched in linear time.
///
/// A parser reads one pattern and is thrown away.
@internal
final class RegexParser {
  /// Creates the parser of [source].
  RegexParser(String source)
    : _points = source.runes.toList(growable: false),
      _offsets = _offsetsOf(source),
      _length = source.length;

  /// The code points of the pattern.
  final List<int> _points;

  /// The index of the code unit every code point starts at.
  final List<int> _offsets;

  /// The number of code units of the pattern.
  final int _length;

  /// The index of the next code point to read.
  var _index = 0;

  /// The most a count of a quantifier is read as; a larger one is too
  /// large to compile anyway.
  static const _largestCount = 1000000000;

  /// Reads the whole pattern.
  ///
  /// Returns its tree.
  ///
  /// Throws a [LinearRegExpException] if it is no pattern or cannot be
  /// matched in linear time.
  RegexNode parse() {
    final RegexNode node = _disjunction();
    if (!_atEnd) {
      throw _syntax('an unmatched )');
    }
    return node;
  }

  /// Reads alternatives separated by `|`.
  ///
  /// Returns them.
  RegexNode _disjunction() {
    final alternatives = <RegexNode>[_alternative()];
    while (_accept(0x7C)) {
      alternatives.add(_alternative());
    }
    if (alternatives.length == 1) {
      return alternatives.single;
    }
    return AlternationNode(List<RegexNode>.unmodifiable(alternatives));
  }

  /// Reads the terms of one alternative, up to a `|`, a `)` or the end.
  ///
  /// Returns them.
  RegexNode _alternative() {
    final parts = <RegexNode>[];
    while (!_atEnd && _peek != 0x7C && _peek != 0x29) {
      parts.add(_term());
    }
    if (parts.isEmpty) {
      return const EmptyNode();
    }
    if (parts.length == 1) {
      return parts.single;
    }
    return SequenceNode(List<RegexNode>.unmodifiable(parts));
  }

  /// Reads an assertion, or an atom and its quantifier.
  ///
  /// Returns it.
  RegexNode _term() {
    final int point = _peek;
    if (point == 0x5E) {
      _index++;
      return const StartNode();
    }
    if (point == 0x24) {
      _index++;
      return const EndNode();
    }
    if (point == 0x5C && _peekAt(1) == 0x62) {
      _index += 2;
      return const WordBoundaryNode(negated: false);
    }
    if (point == 0x5C && _peekAt(1) == 0x42) {
      _index += 2;
      return const WordBoundaryNode(negated: true);
    }
    if (point == 0x28 && _peekAt(1) == 0x3F) {
      final int kind = _peekAt(2);
      final bool behind =
          kind == 0x3C && (_peekAt(3) == 0x3D || _peekAt(3) == 0x21);
      if (kind == 0x3D || kind == 0x21 || behind) {
        throw _unsupported('a lookaround');
      }
    }
    return _quantified(_atom());
  }

  /// Reads the quantifier of [atom], if one follows.
  ///
  /// Returns the atom, repeated as the quantifier says.
  RegexNode _quantified(RegexNode atom) {
    final int start = _index;
    final (int, int?)? bounds = _quantifier();
    if (bounds == null) {
      return atom;
    }
    final (int min, int? max) = bounds;
    if (max != null && max < min) {
      throw LinearRegExpException(
        LinearRegExpFailure.syntax,
        _offsetAt(start),
        'numbers out of order in a quantifier',
      );
    }
    _accept(0x3F);
    return RepetitionNode(atom, min, max);
  }

  /// Reads a quantifier: `*`, `+`, `?` or a count in braces.
  ///
  /// Returns its bounds, or `null` when none follows.
  (int, int?)? _quantifier() {
    if (_atEnd) {
      return null;
    }
    if (_accept(0x2A)) {
      return (0, null);
    }
    if (_accept(0x2B)) {
      return (1, null);
    }
    if (_accept(0x3F)) {
      return (0, 1);
    }
    if (_peek != 0x7B) {
      return null;
    }
    _index++;
    final int? min = _count();
    if (min == null) {
      throw _syntax('a lone {');
    }
    if (_accept(0x7D)) {
      return (min, min);
    }
    if (!_accept(0x2C)) {
      throw _syntax('an unterminated quantifier');
    }
    final int? max = _count();
    if (!_accept(0x7D)) {
      throw _syntax('an unterminated quantifier');
    }
    return (min, max);
  }

  /// Reads a decimal count, at most [_largestCount].
  ///
  /// Returns it, or `null` when no digit follows.
  int? _count() {
    int? value;
    while (!_atEnd && _isDigit(_peek)) {
      final int digit = _points[_index++] - 0x30;
      final int next = (value ?? 0) * 10 + digit;
      value = next > _largestCount ? _largestCount : next;
    }
    return value;
  }

  /// Reads an atom: `.`, a group, a class, an escape or a character.
  ///
  /// Returns it.
  RegexNode _atom() {
    final int point = _peek;
    if (point == 0x2E) {
      _index++;
      return CharacterNode(CodePointClass.anyButLineTerminator);
    }
    if (point == 0x28) {
      return _group();
    }
    if (point == 0x5B) {
      return _class();
    }
    if (point == 0x5C) {
      _index++;
      return _atomEscape();
    }
    if (point == 0x2A || point == 0x2B || point == 0x3F || point == 0x7B) {
      throw _syntax('nothing to repeat');
    }
    if (point == 0x7D || point == 0x5D) {
      throw _syntax('a lone ${String.fromCharCode(point)}');
    }
    _index++;
    return CharacterNode(CodePointClass.single(point));
  }

  /// Reads a group: `(...)`, `(?:...)` or `(?<name>...)`.
  ///
  /// Returns what it holds.
  RegexNode _group() {
    final int start = _index;
    _index++;
    if (_accept(0x3F)) {
      final bool named = _accept(0x3C);
      if (named) {
        _groupName();
      }
      if (!named && !_accept(0x3A)) {
        throw _syntax('an invalid group');
      }
    }
    final RegexNode body = _disjunction();
    if (!_accept(0x29)) {
      throw LinearRegExpException(
        LinearRegExpFailure.syntax,
        _offsetAt(start),
        'an unterminated group',
      );
    }
    return body;
  }

  /// Reads the name of a named group up to its `>`.
  void _groupName() {
    final int start = _index;
    while (!_atEnd && _isNameCharacter(_peek)) {
      _index++;
    }
    if (_index == start || !_accept(0x3E) || _isDigit(_points[start])) {
      throw _syntax('an invalid group name');
    }
  }

  /// Reads an escape outside a class, after its backslash.
  ///
  /// Returns it.
  RegexNode _atomEscape() {
    if (_atEnd) {
      throw _syntax('a trailing backslash');
    }
    final int point = _peek;
    if ((point >= 0x31 && point <= 0x39) || point == 0x6B) {
      throw LinearRegExpException(
        LinearRegExpFailure.unsupported,
        _offsetAt(_index - 1),
        'a backreference',
      );
    }
    final CodePointClass? set = _setEscape();
    if (set != null) {
      return CharacterNode(set);
    }
    return CharacterNode(CodePointClass.single(_characterEscape()));
  }

  /// Reads an escape that stands for a set, `\d` to `\S`, `\p{...}` or
  /// `\P{...}`, after its backslash.
  ///
  /// Returns the set, or `null` when the escape is no such one.
  CodePointClass? _setEscape() {
    final List<int>? ranges = _rangesOf(_peek);
    if (ranges != null) {
      _index++;
      return CodePointClass(ranges);
    }
    if (_peek == 0x70 || _peek == 0x50) {
      return CodePointClass(const <int>[], properties: <RegExp>[_property()]);
    }
    return null;
  }

  /// The ranges of the class escape [point] names: `d`, `D`, `w`, `W`, `s`
  /// or `S`.
  ///
  /// Returns them, or `null` for another letter.
  static List<int>? _rangesOf(int point) => _classEscapes[point];

  /// Reads a property escape, `\p{...}` or `\P{...}`, after its
  /// backslash.
  ///
  /// Returns the `RegExp` that tests one code point for it.
  RegExp _property() {
    final int start = _index;
    final negated = _points[_index++] == 0x50;
    if (!_accept(0x7B)) {
      throw _syntax('a property escape without braces');
    }
    final buffer = StringBuffer();
    while (!_atEnd && _peek != 0x7D) {
      final int point = _points[_index++];
      if (!_isNameCharacter(point) && point != 0x3D) {
        throw _syntax('an invalid property name');
      }
      buffer.writeCharCode(point);
    }
    if (!_accept(0x7D) || buffer.isEmpty) {
      throw _syntax('an unterminated property escape');
    }
    try {
      return RegExp('^\\${negated ? 'P' : 'p'}{$buffer}\$', unicode: true);
    } on FormatException {
      throw LinearRegExpException(
        LinearRegExpFailure.syntax,
        _offsetAt(start),
        'an unknown property',
      );
    }
  }

  /// Reads an escape of one character, after its backslash; `-` only
  /// [inClass].
  ///
  /// Returns its code point.
  int _characterEscape({bool inClass = false}) {
    final int start = _index;
    final int point = _points[_index++];
    final int? control = _controlEscapes[point];
    if (control != null) {
      return control;
    }
    if (point == 0x63) {
      if (_atEnd || !_isLetter(_peek)) {
        throw _syntax('an invalid control escape');
      }
      return _points[_index++] % 32;
    }
    if (point == 0x30) {
      if (!_atEnd && _isDigit(_peek)) {
        throw _syntax('an octal escape');
      }
      return 0;
    }
    if (point == 0x78) {
      return _hex(2, start);
    }
    if (point == 0x75) {
      return _unicodeEscape(start);
    }
    if (_syntaxCharacters.contains(point) || (inClass && point == 0x2D)) {
      return point;
    }
    throw LinearRegExpException(
      LinearRegExpFailure.syntax,
      _offsetAt(start),
      'an invalid escape',
    );
  }

  /// Reads the rest of `\u`: four hexadecimal digits, a surrogate pair of
  /// two such escapes, or hexadecimal digits in braces.
  ///
  /// Returns the code point.
  int _unicodeEscape(int start) {
    if (_accept(0x7B)) {
      var value = 0;
      var digits = 0;
      while (!_atEnd && _hexValue(_peek) != null) {
        value = value * 16 + _hexValue(_points[_index++])!;
        digits++;
        if (value > CodePointClass.maxCodePoint) {
          throw _syntax('a code point beyond U+10FFFF');
        }
      }
      if (digits == 0 || !_accept(0x7D)) {
        throw _syntax('an invalid unicode escape');
      }
      return value;
    }
    final int lead = _hex(4, start);
    final bool pairs =
        lead >= 0xD800 &&
        lead <= 0xDBFF &&
        _peekAt(0) == 0x5C &&
        _peekAt(1) == 0x75;
    if (!pairs) {
      return lead;
    }
    final int mark = _index;
    _index += 2;
    final int? trail = _optionalHex(4);
    if (trail == null || trail < 0xDC00 || trail > 0xDFFF) {
      _index = mark;
      return lead;
    }
    return 0x10000 + ((lead - 0xD800) << 10) + (trail - 0xDC00);
  }

  /// Reads exactly [count] hexadecimal digits of an escape that started
  /// at [start].
  ///
  /// Returns their value.
  int _hex(int count, int start) {
    final int? value = _optionalHex(count);
    if (value == null) {
      throw LinearRegExpException(
        LinearRegExpFailure.syntax,
        _offsetAt(start),
        'an invalid hexadecimal escape',
      );
    }
    return value;
  }

  /// Reads exactly [count] hexadecimal digits.
  ///
  /// Returns their value, or `null`, reading nothing, when fewer follow.
  int? _optionalHex(int count) {
    var value = 0;
    for (var offset = 0; offset < count; offset++) {
      final int? digit = _hexValue(_peekAt(offset));
      if (digit == null) {
        return null;
      }
      value = value * 16 + digit;
    }
    _index += count;
    return value;
  }

  /// Reads a class, `[...]` or `[^...]`.
  ///
  /// Returns it.
  RegexNode _class() {
    final int start = _index;
    _index++;
    final bool negated = _accept(0x5E);
    final ranges = <int>[];
    final properties = <RegExp>[];
    while (!_atEnd && _peek != 0x5D) {
      final (int? first, CodePointClass? firstSet) = _classAtom();
      final bool isRange =
          _peekAt(0) == 0x2D && _peekAt(1) != 0x5D && _peekAt(1) != -1;
      if (!isRange) {
        _addTo(ranges, properties, first, firstSet);
        continue;
      }
      _index++;
      final (int? last, CodePointClass? lastSet) = _classAtom();
      if (first == null ||
          last == null ||
          firstSet != null ||
          lastSet != null) {
        throw _syntax('a class escape in a range');
      }
      if (last < first) {
        throw _syntax('a range out of order');
      }
      ranges
        ..add(first)
        ..add(last);
    }
    if (!_accept(0x5D)) {
      throw LinearRegExpException(
        LinearRegExpFailure.syntax,
        _offsetAt(start),
        'an unterminated class',
      );
    }
    return CharacterNode(
      CodePointClass(ranges, properties: properties, negated: negated),
    );
  }

  /// Adds the code point [single] or the set [set] to the [ranges] and
  /// [properties] of a class.
  static void _addTo(
    List<int> ranges,
    List<RegExp> properties,
    int? single,
    CodePointClass? set,
  ) {
    if (single != null) {
      ranges
        ..add(single)
        ..add(single);
      return;
    }
    if (set != null) {
      ranges.addAll(set.ranges);
      properties.addAll(set.properties);
    }
  }

  /// Reads one atom of a class: a character, an escape of one or a set.
  ///
  /// Returns the code point, or the set.
  (int?, CodePointClass?) _classAtom() {
    final int point = _points[_index++];
    if (point != 0x5C) {
      return (point, null);
    }
    if (_atEnd) {
      throw _syntax('a trailing backslash');
    }
    final int escaped = _peek;
    if (escaped == 0x62) {
      _index++;
      return (0x08, null);
    }
    if ((escaped >= 0x31 && escaped <= 0x39) || escaped == 0x6B) {
      throw _syntax('a backreference in a class');
    }
    final CodePointClass? set = _setEscape();
    if (set != null) {
      return (null, set);
    }
    return (_characterEscape(inClass: true), null);
  }

  /// Whether every code point was read.
  bool get _atEnd => _index >= _points.length;

  /// The next code point.
  int get _peek => _points[_index];

  /// The code point [ahead] after the next one, or `-1` past the end.
  int _peekAt(int ahead) {
    final int at = _index + ahead;
    return at < _points.length ? _points[at] : -1;
  }

  /// Reads [point] if it is the next one.
  ///
  /// Returns whether it was.
  bool _accept(int point) {
    if (!_atEnd && _peek == point) {
      _index++;
      return true;
    }
    return false;
  }

  /// The index of the code unit the code point at [index] starts at.
  int _offsetAt(int index) =>
      index < _offsets.length ? _offsets[index] : _length;

  /// A syntax problem at the next code point, explained by [detail].
  LinearRegExpException _syntax(String detail) => LinearRegExpException(
    LinearRegExpFailure.syntax,
    _offsetAt(_index),
    detail,
  );

  /// What cannot be matched in linear time, at the next code point.
  LinearRegExpException _unsupported(String detail) => LinearRegExpException(
    LinearRegExpFailure.unsupported,
    _offsetAt(_index),
    detail,
  );

  /// The index of the code unit every code point of [source] starts at.
  static List<int> _offsetsOf(String source) {
    final offsets = <int>[];
    var offset = 0;
    for (final int point in source.runes) {
      offsets.add(offset);
      offset += point > 0xFFFF ? 2 : 1;
    }
    return List<int>.unmodifiable(offsets);
  }

  /// Whether [point] is a decimal digit.
  static bool _isDigit(int point) => point >= 0x30 && point <= 0x39;

  /// Whether [point] is an ASCII letter.
  static bool _isLetter(int point) =>
      (point >= 0x41 && point <= 0x5A) || (point >= 0x61 && point <= 0x7A);

  /// Whether [point] may be part of the name of a group or a property.
  static bool _isNameCharacter(int point) =>
      _isLetter(point) || _isDigit(point) || point == 0x5F || point == 0x24;

  /// The value of the hexadecimal digit [point], or `null`.
  static int? _hexValue(int point) {
    if (_isDigit(point)) {
      return point - 0x30;
    }
    if (point >= 0x41 && point <= 0x46) {
      return point - 0x37;
    }
    if (point >= 0x61 && point <= 0x66) {
      return point - 0x57;
    }
    return null;
  }

  /// The characters of the syntax, which an escape stands for as they
  /// are, and `/`.
  static const _syntaxCharacters = <int>{
    0x24,
    0x28,
    0x29,
    0x2A,
    0x2B,
    0x2E,
    0x2F,
    0x3F,
    0x5B,
    0x5C,
    0x5D,
    0x5E,
    0x7B,
    0x7C,
    0x7D,
  };

  /// The ranges of every class escape, by its letter.
  static final _classEscapes = <int, List<int>>{
    0x64: CodePointClass.digits,
    0x44: CodePointClass.complement(CodePointClass.digits),
    0x77: CodePointClass.wordCharacters,
    0x57: CodePointClass.complement(CodePointClass.wordCharacters),
    0x73: CodePointClass.whiteSpace,
    0x53: CodePointClass.complement(CodePointClass.whiteSpace),
  };

  /// The code point of every control escape, by its letter.
  static const _controlEscapes = <int, int>{
    0x66: 0x0C,
    0x6E: 0x0A,
    0x72: 0x0D,
    0x74: 0x09,
    0x76: 0x0B,
  };
}
