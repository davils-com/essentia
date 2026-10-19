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

import 'package:essentia_core/src/version/internal/version_steps.dart';
import 'package:essentia_core/src/version/semantic_version.dart';
import 'package:meta/meta.dart';

/// A version as a comparator of a range writes it: up to three numbers,
/// where `1.2`, `1.2.x` and `1.2.*` all stand for the whole 1.2 line.
@internal
@immutable
final class Partial {
  /// Creates the partial version of the [numbers] given, with the complete
  /// [version] when all three were.
  const Partial(this.numbers, this.version);

  /// The numbers given, none for `*`.
  final List<int> numbers;

  /// The complete version, or `null` when a number was left out.
  final SemanticVersion? version;

  /// Whether no number was given, so that every version is meant.
  bool get isAny => numbers.isEmpty;

  /// The lowest version of the line: the version itself, or the release
  /// with zeros for the numbers left out.
  ///
  /// Returns that version.
  SemanticVersion lowest() => version ?? releaseFloor(numbers);

  /// The first version above the line: the [successor] of a complete
  /// version, or the pre-release floor of the next line.
  ///
  /// Returns that version, or `null` when there is none.
  SemanticVersion? firstAbove() {
    final SemanticVersion? complete = version;
    if (complete == null) {
      return floorAbove(numbers);
    }
    return successor(complete);
  }
}
