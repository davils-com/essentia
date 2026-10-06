/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

/// A schema without any parameter.
final class EmptyParameters extends Parameters {
  /// Nothing.
  @override
  List<Parameter<Object?>> get declared => const <Parameter<Object?>>[];
}
