/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

/// A schema whose rules quote the value they refuse.
final class QuotingRuleParameters extends Parameters {
  /// Creates the schema.
  QuotingRuleParameters();

  /// A secret whose rule quotes it.
  final Parameter<String?> token = parameter(<String>['--token'])
      .sensitive()
      .validate(_checkToken);

  /// Plain text whose rule quotes it.
  final Parameter<String?> name = parameter(<String>['--name'])
      .validate(_checkName);

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[token, name];

  /// Reports [value] through [it] unless it starts with `sk-`.
  static void _checkToken(ValidationScope it, String value) {
    if (!value.startsWith('sk-')) {
      it.fail("'$value' is not a valid token");
    }
  }

  /// Reports [value] through [it] when it is shorter than three characters.
  static void _checkName(ValidationScope it, String value) {
    if (value.length < 3) {
      it.fail("'$value' is too short");
    }
  }
}
