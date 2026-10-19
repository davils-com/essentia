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

/// A schema of choices that fall back to defaults given to its
/// constructor.
final class ChoiceDefaultParameters extends Parameters {
  /// Creates the schema falling back to [levelDefault] for `--level`, to
  /// [levelsDefault] for `--levels` and to [tierDefault] for `--tier`.
  ChoiceDefaultParameters({
    String levelDefault = 'low',
    List<String> levelsDefault = const <String>['low'],
    String tierDefault = 'gold',
  }) : level = parameter(<String>['--level'])
           .choice(<String>['low', 'high'])
           .defaultsTo(levelDefault),
       levels = parameter(<String>['--levels'])
           .choice(<String>['low', 'high'])
           .multiple()
           .defaultsTo(levelsDefault),
       tier = parameter(<String>['--tier'])
           .choice(<String>['gold', 'silver'])
           .sensitive()
           .defaultsTo(tierDefault);

  /// One of `low` and `high`.
  final Parameter<String> level;

  /// Several of `low` and `high`.
  final Parameter<List<String>> levels;

  /// A secret one of `gold` and `silver`.
  final Parameter<String> tier;

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    level,
    levels,
    tier,
  ];
}
