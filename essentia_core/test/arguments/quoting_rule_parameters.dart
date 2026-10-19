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

import 'package:essentia_core/essentia_core.dart';

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
