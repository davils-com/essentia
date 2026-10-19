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
import 'package:meta/meta.dart';

/// One instruction of the program a pattern of `LinearRegExp` compiles
/// to, run by a Pike machine that follows every thread at once.
@internal
@immutable
sealed class RegexInstruction {
  /// Creates the instruction.
  const RegexInstruction();
}

/// Consumes one code point of [characters] and goes on with the next
/// instruction.
@internal
final class ConsumeInstruction extends RegexInstruction {
  /// Creates the instruction of [characters].
  const ConsumeInstruction(this.characters);

  /// The code points it consumes.
  final CodePointClass characters;
}

/// Goes on with both [first] and [second].
@internal
final class SplitInstruction extends RegexInstruction {
  /// Creates the instruction.
  const SplitInstruction(this.first, this.second);

  /// The index of one instruction to go on with.
  final int first;

  /// The index of the other instruction to go on with.
  final int second;
}

/// Goes on with [target].
@internal
final class JumpInstruction extends RegexInstruction {
  /// Creates the instruction.
  const JumpInstruction(this.target);

  /// The index of the instruction to go on with.
  final int target;
}

/// Goes on only at the start of the text.
@internal
final class StartInstruction extends RegexInstruction {
  /// Creates the instruction.
  const StartInstruction();
}

/// Goes on only at the end of the text.
@internal
final class EndInstruction extends RegexInstruction {
  /// Creates the instruction.
  const EndInstruction();
}

/// Goes on only at a word boundary, or only where there is none when
/// [negated].
@internal
final class WordBoundaryInstruction extends RegexInstruction {
  /// Creates the instruction.
  const WordBoundaryInstruction({required this.negated});

  /// Whether it goes on where there is no boundary.
  final bool negated;
}

/// The pattern matched.
@internal
final class AcceptInstruction extends RegexInstruction {
  /// Creates the instruction.
  const AcceptInstruction();
}
