/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

/// A schema of several flags with long, similar names.
final class ManyFlagParameters extends Parameters {
  /// Creates the schema.
  ManyFlagParameters();

  /// The first numbered flag.
  final Parameter<bool> first = flag(<String>['--parameter-number-0']);

  /// The second numbered flag.
  final Parameter<bool> second = flag(<String>['--parameter-number-1']);

  /// The third numbered flag.
  final Parameter<bool> third = flag(<String>['--parameter-number-2']);

  /// A short flag name.
  final Parameter<bool> mode = flag(<String>['--mode']);

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    first,
    second,
    third,
    mode,
  ];
}
