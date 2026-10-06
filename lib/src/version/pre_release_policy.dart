/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
