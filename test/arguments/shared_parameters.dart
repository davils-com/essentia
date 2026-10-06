/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

/// A schema declaring a parameter it is handed, which is how one parameter
/// ends up listed by two schemas.
final class SharedParameters extends Parameters {
  /// Creates the schema declaring [shared].
  SharedParameters(this.shared);

  /// The parameter handed to the constructor.
  final Parameter<String?> shared;

  /// Only [shared].
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[shared];
}
