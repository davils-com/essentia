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

/// Whether a pre-release counts as inside a `SemanticVersionRange`.
///
/// By precedence `1.5.0-beta` lies between `1.2.0` and `2.0.0`, so it is
/// inside `^1.2.0`. The specification is right about that, and a dependency
/// resolver almost never wants it: a pre-release promises nothing, and a
/// range that did not ask for one should not select one. npm, Cargo and
/// Composer therefore all let a pre-release match only where the range
/// itself names a pre-release of the same version - this enum is that
/// choice made explicit.
///
/// ```dart
/// final range = SemanticVersionRange.parse('>1.2.3-alpha.3');
///
/// range.contains(
///   SemanticVersion.parse('1.2.3-alpha.7'),
///   PreReleasePolicy.sameCoreOnly,
/// ); // true
/// range.contains(
///   SemanticVersion.parse('3.4.5-alpha.9'),
///   PreReleasePolicy.sameCoreOnly,
/// ); // false
/// range.contains(
///   SemanticVersion.parse('3.4.5-alpha.9'),
///   PreReleasePolicy.byPrecedence,
/// ); // true
/// ```
///
/// A release is decided by precedence under every policy; the policies
/// differ only for a pre-release.
enum PreReleasePolicy {
  /// A pre-release is inside wherever its precedence puts it. The
  /// set-theoretic answer, and what `range.contains(version)` means.
  byPrecedence,

  /// A pre-release is inside only when the interval holding it has a bound,
  /// as the range renders it, that is a pre-release of the same major, minor
  /// and patch - npm's rule. `>=1.2.3-rc.1 <2` admits `1.2.3-rc.4` and not
  /// `1.4.0-beta`.
  sameCoreOnly,

  /// No pre-release is ever inside, whatever the range names.
  releasesOnly,
}
