/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

/// A schema whose converters throw something other than a
/// `ConversionException`.
final class CarelessParameters extends Parameters {
  /// Creates the schema.
  CarelessParameters();

  /// Converted by [int.parse], which throws a [FormatException].
  final Parameter<int?> port = parameter(<String>['--port'])
      .convert<int>('port', int.parse);

  /// Converted by the built-in integer conversion.
  final Parameter<int?> workers = parameter(<String>['--workers']).integer();

  /// A secret converted by [int.parse], whose exception quotes the value.
  final Parameter<int?> pin = parameter(<String>['--pin'])
      .sensitive()
      .convert<int>('pin', int.parse);

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    port,
    workers,
    pin,
  ];
}
