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

import 'package:essentia_core/src/validation/violation_code.dart';

/// The stable identifiers of what can be wrong with a stated `Principal`.
///
/// A message may be reworded at any time; these do not change.
abstract final class PrincipalViolationCodes {
  /// The id is blank.
  static const blankId = ViolationCode('essentia.principal.blank-id');

  /// A role is blank.
  static const blankRole = ViolationCode('essentia.principal.blank-role');

  /// A tenant was set, and set to blank.
  static const blankTenant = ViolationCode('essentia.principal.blank-tenant');

  /// A display name was set, and set to blank.
  static const blankDisplayName = ViolationCode(
    'essentia.principal.blank-display-name',
  );

  /// An attribute was given a blank name.
  static const invalidAttribute = ViolationCode(
    'essentia.principal.invalid-attribute',
  );

  /// A principal was made to act on behalf of itself.
  static const selfDelegation = ViolationCode(
    'essentia.principal.self-delegation',
  );

  /// A delegation chain is longer than `Principal.maxChainLength`.
  static const delegationTooDeep = ViolationCode(
    'essentia.principal.delegation-too-deep',
  );
}
