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

import 'package:essentia_core/src/text/internal/regex_instruction.dart';
import 'package:essentia_core/src/text/internal/regex_node.dart';
import 'package:essentia_core/src/text/linear_reg_exp_exception.dart';
import 'package:essentia_core/src/text/linear_reg_exp_failure.dart';
import 'package:meta/meta.dart';

/// Compiles the tree of a pattern into the program of a Pike machine,
/// refusing one of more than [maxInstructions] instructions.
///
/// A compiler compiles one pattern and is thrown away.
@internal
final class RegexCompiler {
  /// Creates the compiler of programs of at most [maxInstructions].
  RegexCompiler(this.maxInstructions);

  /// The most instructions a program may have.
  final int maxInstructions;

  /// The instructions written so far.
  final _program = <RegexInstruction>[];

  /// Compiles [node], followed by the instruction that accepts.
  ///
  /// Returns the program.
  ///
  /// Throws a [LinearRegExpException] if it has more than
  /// [maxInstructions] instructions.
  List<RegexInstruction> compile(RegexNode node) {
    _emit(node);
    _add(const AcceptInstruction());
    return List<RegexInstruction>.unmodifiable(_program);
  }

  /// Writes the instructions of [node].
  void _emit(RegexNode node) {
    switch (node) {
      case EmptyNode():
        return;
      case CharacterNode(:final characters):
        _add(ConsumeInstruction(characters));
      case SequenceNode(:final parts):
        parts.forEach(_emit);
      case AlternationNode(:final alternatives):
        _alternation(alternatives);
      case RepetitionNode(:final body, :final min, :final max):
        _repetition(body, min, max);
      case StartNode():
        _add(const StartInstruction());
      case EndNode():
        _add(const EndInstruction());
      case WordBoundaryNode(:final negated):
        _add(WordBoundaryInstruction(negated: negated));
    }
  }

  /// Writes one of [alternatives]: a split before every one but the
  /// last, and a jump past the rest after it.
  void _alternation(List<RegexNode> alternatives) {
    final exits = <int>[];
    for (var index = 0; index < alternatives.length - 1; index++) {
      final int split = _add(const JumpInstruction(-1));
      _emit(alternatives[index]);
      exits.add(_add(const JumpInstruction(-1)));
      _program[split] = SplitInstruction(split + 1, _program.length);
    }
    _emit(alternatives.last);
    for (final exit in exits) {
      _program[exit] = JumpInstruction(_program.length);
    }
  }

  /// Writes [body] [min] times, then [max] minus [min] times more, each
  /// of those optional, or a loop over it when [max] is `null`.
  void _repetition(RegexNode body, int min, int? max) {
    for (var index = 0; index < min; index++) {
      _emit(body);
    }
    if (max == null) {
      final int loop = _add(const JumpInstruction(-1));
      _emit(body);
      _add(JumpInstruction(loop));
      _program[loop] = SplitInstruction(loop + 1, _program.length);
      return;
    }
    final skips = <int>[];
    for (var index = min; index < max; index++) {
      skips.add(_add(const JumpInstruction(-1)));
      _emit(body);
    }
    for (final skip in skips) {
      _program[skip] = SplitInstruction(skip + 1, _program.length);
    }
  }

  /// Appends [instruction].
  ///
  /// Returns its index.
  ///
  /// Throws a [LinearRegExpException] if the program is full.
  int _add(RegexInstruction instruction) {
    if (_program.length >= maxInstructions) {
      throw LinearRegExpException(
        LinearRegExpFailure.tooComplex,
        0,
        'more than $maxInstructions instructions',
      );
    }
    _program.add(instruction);
    return _program.length - 1;
  }
}
