/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
