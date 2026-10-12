/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

/// A schema whose parameters split on an empty delimiter, which is refused
/// as each of them is declared.
final class EmptyDelimiterParameters extends Parameters {
  /// Creates the schema.
  EmptyDelimiterParameters();

  /// Splits on nothing.
  final Parameter<List<String>> tags = parameter(<String>['--tag']).split('');

  /// Repeatable, and splits on nothing.
  final Parameter<List<String>> repeated = parameter(<String>['--repeated'])
      .multiple()
      .split('');

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[tags, repeated];
}
