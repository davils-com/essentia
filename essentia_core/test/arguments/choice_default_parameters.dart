/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
