/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

/// The parameters the example accepts.
final class ExampleParameters extends Parameters {
  /// Creates the schema, falling back to `EXAMPLE_*` variables.
  ExampleParameters() : super(environmentPrefix: 'EXAMPLE');

  /// Who to greet, repeatable.
  late final Parameter<List<String>> names = parameter(<String>['--name', '-n'])
      .multiple()
      .defaultsTo(<String>['world'])
      .describedAs('who to greet');

  /// How often to greet everybody.
  late final Parameter<int> times = parameter(<String>['--times'])
      .integer()
      .validate((it, value) {
        if (value < 1) {
          it.fail('must be at least one');
        }
      })
      .defaultsTo(1)
      .describedAs('how often to greet');

  /// Every parameter, in the order of the usage listing.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[names, times];
}
