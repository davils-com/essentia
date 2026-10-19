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
