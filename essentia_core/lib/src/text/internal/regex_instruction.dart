/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
