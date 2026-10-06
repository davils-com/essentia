/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

/// A schema that collects the arguments it does not declare.
final class LenientParameters extends Parameters {
  /// Creates the schema.
  LenientParameters() : super(unknownArguments: UnknownArgumentPolicy.collect);

  /// The only declared parameter.
  final Parameter<String?> name = parameter(<String>['--name']);

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[name];
}
