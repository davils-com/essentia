/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

/// A schema with one parameter whose name is wider than every column.
final class LongNameParameters extends Parameters {
  /// Creates the schema.
  LongNameParameters();

  /// A required parameter with a name of 37 characters.
  final Parameter<int> long = parameter(<String>[
    '--a-parameter-with-a-really-long-name',
  ]).integer().required();

  /// A required parameter with a short name.
  final Parameter<int> short = parameter(<String>['--b']).integer().required();

  /// Every parameter, in the order of the usage listing.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[long, short];
}
