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

/// A part of a parsed pattern of `LinearRegExp`.
@internal
@immutable
sealed class RegexNode {
  /// Creates the part.
  const RegexNode();
}

/// What matches the empty text, such as an empty alternative.
@internal
final class EmptyNode extends RegexNode {
  /// Creates the part.
  const EmptyNode();
}

/// One code point of [characters].
@internal
final class CharacterNode extends RegexNode {
  /// Creates the part of [characters].
  const CharacterNode(this.characters);

  /// The code points it may consume.
  final CodePointClass characters;
}

/// The [parts] one after another.
@internal
final class SequenceNode extends RegexNode {
  /// Creates the part of [parts].
  const SequenceNode(this.parts);

  /// The parts, in order.
  final List<RegexNode> parts;
}

/// One of the [alternatives].
@internal
final class AlternationNode extends RegexNode {
  /// Creates the part of [alternatives].
  const AlternationNode(this.alternatives);

  /// The alternatives.
  final List<RegexNode> alternatives;
}

/// [body] at least [min] and at most [max] times, or without an upper
/// bound when [max] is `null`.
@internal
final class RepetitionNode extends RegexNode {
  /// Creates the part of [body] repeated from [min] to [max] times.
  const RepetitionNode(this.body, this.min, this.max);

  /// What is repeated.
  final RegexNode body;

  /// The fewest repetitions.
  final int min;

  /// The most repetitions, or `null` for no bound.
  final int? max;
}

/// The start of the text: `^`.
@internal
final class StartNode extends RegexNode {
  /// Creates the part.
  const StartNode();
}

/// The end of the text: `$`.
@internal
final class EndNode extends RegexNode {
  /// Creates the part.
  const EndNode();
}

/// A boundary between a word character and another, `\b`, or no
/// boundary, `\B`, when [negated].
@internal
final class WordBoundaryNode extends RegexNode {
  /// Creates the part.
  const WordBoundaryNode({required this.negated});

  /// Whether it stands where there is no boundary.
  final bool negated;
}
