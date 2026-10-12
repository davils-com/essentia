/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

/// A schema using every option on every kind of builder: flags, plain,
/// required, defaulted and multiple parameters.
final class OptionedParameters extends Parameters {
  /// Creates the schema, with the environment prefix `APP`.
  OptionedParameters() : super(environmentPrefix: 'APP');

  /// A flag fed from `VERBOSE`, with a description.
  final Parameter<bool> verbose = flag(<String>['--verbose'])
      .env('VERBOSE')
      .describedAs('Talks about everything it does');

  /// A flag that never reads the environment.
  final Parameter<bool> quiet = flag(<String>['--quiet']).noEnv();

  /// A plain parameter with a description.
  final Parameter<String?> name = parameter(<String>['--name'])
      .describedAs('The name of the instance');

  /// A required secret fed from `TOKEN`, at least three characters long.
  final Parameter<String> token = parameter(<String>['--token'])
      .required()
      .sensitive()
      .env('TOKEN')
      .validate((it, value) {
        if (value.length < 3) {
          it.fail('is shorter than three characters');
        }
      });

  /// A required parameter that never reads the environment and is on its
  /// way out.
  final Parameter<String> id = parameter(<String>['--id'])
      .required()
      .noEnv()
      .deprecated('use --name instead');

  /// A defaulted secret fed from `LEVEL`, one of three levels.
  final Parameter<String> level = parameter(<String>['--level'])
      .defaultsTo('info')
      .sensitive()
      .env('LEVEL')
      .describedAs('How much to log')
      .validate((it, value) {
        if (!<String>{'debug', 'info', 'warn'}.contains(value)) {
          it.fail('is no level');
        }
      });

  /// A defaulted parameter that never reads the environment and is on its
  /// way out.
  final Parameter<String> mode = parameter(<String>['--mode'])
      .defaultsTo('fast')
      .noEnv()
      .deprecated();

  /// A secret list on its way out, with a description.
  final Parameter<List<String>> tags = parameter(<String>['--tag'])
      .multiple()
      .sensitive()
      .env('TAGS')
      .describedAs('Labels of the instance')
      .deprecated('use --label instead');

  /// A list that never reads the environment.
  final Parameter<List<String>> labels = parameter(<String>['--label'])
      .multiple()
      .noEnv();

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    verbose,
    quiet,
    name,
    token,
    id,
    level,
    mode,
    tags,
    labels,
  ];
}
