/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// The stable identifier of a kind of problem.
///
/// A message is written for a person and may be reworded at any time; a
/// code is written for a program and does not change. A code is what a
/// caller matches on to react to a particular problem, and what a
/// translation is keyed by.
///
/// The convention is dot-separated and lowercase, namespaced by whoever
/// defines it, with the specific problem in kebab-case:
/// `essentia.parameter.missing-required`, `leaf.sink.duplicate-name`. Codes
/// are deliberately plain strings so that anything building on Essentia can
/// define its own without asking.
extension type const ViolationCode(String value) implements Object {
  /// A value failed a rule declared for it and nothing more specific was
  /// said.
  static const invalid = ViolationCode('essentia.validation.invalid');

  /// Something that has to be set was not.
  static const required = ViolationCode('essentia.validation.required');

  /// Something is still honoured but should no longer be used.
  static const deprecated = ViolationCode('essentia.validation.deprecated');
}
