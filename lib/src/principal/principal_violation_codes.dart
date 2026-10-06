/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/validation/violation_code.dart';

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
