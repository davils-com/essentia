/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

/// A schema declaring two parameters under names given from outside, and
/// one parameter it forgets to list.
final class NamedParameters extends Parameters {
  /// Creates the schema declaring [firstNames] and [secondNames].
  NamedParameters(List<String> firstNames, List<String> secondNames)
    : first = parameter(firstNames),
      second = parameter(secondNames);

  /// Answers to the first names.
  final Parameter<String?> first;

  /// Answers to the second names.
  final Parameter<String?> second;

  /// Created on the schema but missing from [declared].
  final Parameter<String?> orphan = parameter(<String>['--orphan']);

  /// [first] and [second], but not [orphan].
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[first, second];
}
