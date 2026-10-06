/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/arguments.dart';

/// A schema declaring two parameters under names given from outside, and
/// one parameter it forgets to list.
final class NamedParameters extends Parameters {
  /// Creates the schema declaring [_firstNames] and [_secondNames].
  NamedParameters(this._firstNames, this._secondNames);

  /// The names of [first].
  final List<String> _firstNames;

  /// The names of [second].
  final List<String> _secondNames;

  /// Answers to the first names.
  late final Parameter<String?> first = parameter(_firstNames);

  /// Answers to the second names.
  late final Parameter<String?> second = parameter(_secondNames);

  /// Created on the schema but missing from [declared].
  late final Parameter<String?> orphan = parameter(<String>['--orphan']);

  /// [first] and [second], but not [orphan].
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[first, second];
}
