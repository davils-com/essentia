/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

/// A schema of two short flags and a short parameter taking a value, for
/// reading bundles.
final class BundleParameters extends Parameters {
  /// Creates the schema, treating unknown arguments by [policy].
  BundleParameters([
    UnknownArgumentPolicy policy = UnknownArgumentPolicy.reject,
  ]) : super(unknownArguments: policy);

  /// A short flag.
  late final Parameter<bool> all = flag(<String>['-a']);

  /// Another short flag.
  late final Parameter<bool> colour = flag(<String>['-c']);

  /// A short parameter taking an integer.
  late final Parameter<int?> port = parameter(<String>['-p']).integer();

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    all,
    colour,
    port,
  ];
}
