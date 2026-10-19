/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/text/internal/code_point_class.dart';
import 'package:essentia_core/src/text/internal/regex_compiler.dart';
import 'package:essentia_core/src/text/internal/regex_instruction.dart';
import 'package:essentia_core/src/text/internal/regex_parser.dart';
import 'package:essentia_core/src/text/linear_reg_exp_exception.dart';
import 'package:meta/meta.dart';

/// A regular expression of ECMAScript, in its unicode mode, that is
/// matched in time linear in the length of the text, whatever the pattern.
///
/// ```dart
/// final pattern = LinearRegExp(r'^[a-z]+(-[a-z]+)*$');
/// pattern.hasMatch('two-words');
/// ```
///
/// A `RegExp` backtracks: a pattern such as `(a+)+$` takes time
/// exponential in the length of a text it does not match, so a pattern
/// from a document nobody trusts, such as the `pattern` of a JSON Schema,
/// can stop a process. A `LinearRegExp` follows every way through the
/// pattern at once, as RE2 does, so matching costs at most the length of
/// the text, in code points, times [instructionCount].
///
/// It knows the syntax of ECMAScript in its unicode mode: alternatives,
/// groups of every kind, the quantifiers with their counts and lazy forms,
/// `^`, `$`, `\b` and `\B`, `.`, classes with their ranges, the escapes of
/// characters, `\d`, `\w`, `\s` and their negations, and the Unicode
/// properties of `\p{...}` and `\P{...}`. It refuses with a
/// [LinearRegExpException] what no linear machine can match - a
/// backreference, a lookahead and a lookbehind - and a pattern whose
/// program would exceed `maxInstructions`, as a large count of
/// repetitions makes one. It has no flags: it is case sensitive and `^`
/// and `$` stand for the start and the end of the whole text.
///
/// It answers whether the pattern matches somewhere in a text, which is
/// what a validation needs; it reports no positions or groups.
@immutable
final class LinearRegExp {
  /// Compiles [pattern] into a program of at most [maxInstructions].
  ///
  /// Throws a [LinearRegExpException] if [pattern] is no pattern of
  /// ECMAScript in its unicode mode, uses what cannot be matched in linear
  /// time, or compiles to too many instructions.
  factory LinearRegExp(
    String pattern, {
    int maxInstructions = defaultMaxInstructions,
  }) {
    if (maxInstructions < 1) {
      throw ArgumentError.value(
        maxInstructions,
        'maxInstructions',
        'must be at least 1',
      );
    }
    return LinearRegExp._(
      pattern,
      RegexCompiler(maxInstructions).compile(RegexParser(pattern).parse()),
    );
  }

  /// Creates the expression of [pattern] compiled into [_program].
  const LinearRegExp._(this.pattern, this._program);

  /// How many instructions a program may have unless told otherwise.
  static const defaultMaxInstructions = 2000;

  /// The pattern, as it was given.
  final String pattern;

  /// The program the pattern compiled to.
  final List<RegexInstruction> _program;

  /// The number of instructions of the program: the factor the length of
  /// a text is multiplied with to bound the cost of matching it.
  int get instructionCount => _program.length;

  /// Whether the pattern matches somewhere in [input].
  ///
  /// It takes at most the number of code points of [input] times
  /// [instructionCount] steps.
  bool hasMatch(String input) {
    final List<int> points = input.runes.toList(growable: false);
    final marks = List<int>.filled(_program.length, -1);
    final pending = <int>[];
    var current = <int>[];
    var next = <int>[];
    for (var position = 0; ; position++) {
      if (_follow(points, 0, position, current, marks, pending)) {
        return true;
      }
      if (position == points.length) {
        return false;
      }
      next.clear();
      final int point = points[position];
      for (final counter in current) {
        final instruction = _program[counter] as ConsumeInstruction;
        if (instruction.characters.matches(point) &&
            _follow(points, counter + 1, position + 1, next, marks, pending)) {
          return true;
        }
      }
      final swap = current;
      current = next;
      next = swap;
    }
  }

  /// Follows the instructions that consume nothing from [start] at
  /// [position], collecting in [threads] those that consume a code point.
  ///
  /// [marks] holds the position every instruction was last reached at, so
  /// that none is followed twice for one position; [pending] is the stack
  /// of instructions still to follow.
  ///
  /// Returns whether the pattern is accepted on the way.
  bool _follow(
    List<int> points,
    int start,
    int position,
    List<int> threads,
    List<int> marks,
    List<int> pending,
  ) {
    pending
      ..clear()
      ..add(start);
    while (pending.isNotEmpty) {
      final int counter = pending.removeLast();
      if (marks[counter] == position) {
        continue;
      }
      marks[counter] = position;
      switch (_program[counter]) {
        case ConsumeInstruction():
          threads.add(counter);
        case SplitInstruction(:final int first, :final int second):
          pending
            ..add(second)
            ..add(first);
        case JumpInstruction(:final int target):
          pending.add(target);
        case StartInstruction():
          if (position == 0) {
            pending.add(counter + 1);
          }
        case EndInstruction():
          if (position == points.length) {
            pending.add(counter + 1);
          }
        case WordBoundaryInstruction(:final bool negated):
          if (_isBoundary(points, position) != negated) {
            pending.add(counter + 1);
          }
        case AcceptInstruction():
          return true;
      }
    }
    return false;
  }

  /// Whether a word character is on exactly one side of [position].
  static bool _isBoundary(List<int> points, int position) {
    final bool before = position > 0 && _isWord(points[position - 1]);
    final bool after = position < points.length && _isWord(points[position]);
    return before != after;
  }

  /// The class of the word characters of `\b`.
  static final _word = CodePointClass(CodePointClass.wordCharacters);

  /// Whether [point] is a word character.
  static bool _isWord(int point) => _word.matches(point);

  /// The pattern.
  @override
  String toString() => 'LinearRegExp($pattern)';
}
