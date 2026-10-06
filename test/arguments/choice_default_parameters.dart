/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

/// A schema of choices that fall back to defaults given to its
/// constructor.
final class ChoiceDefaultParameters extends Parameters {
  /// Creates the schema falling back to [_level] for `--level`, to
  /// [_levels] for `--levels` and to [_tier] for `--tier`.
  ChoiceDefaultParameters({
    this._level = 'low',
    this._levels = const <String>['low'],
    this._tier = 'gold',
  });

  /// The default of `--level`.
  final String _level;

  /// The default of `--levels`.
  final List<String> _levels;

  /// The default of `--tier`.
  final String _tier;

  /// One of `low` and `high`.
  late final Parameter<String> level = parameter(<String>['--level'])
      .choice(<String>['low', 'high'])
      .defaultsTo(_level);

  /// Several of `low` and `high`.
  late final Parameter<List<String>> levels = parameter(<String>['--levels'])
      .choice(<String>['low', 'high'])
      .multiple()
      .defaultsTo(_levels);

  /// A secret one of `gold` and `silver`.
  late final Parameter<String> tier = parameter(<String>['--tier'])
      .choice(<String>['gold', 'silver'])
      .sensitive()
      .defaultsTo(_tier);

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    level,
    levels,
    tier,
  ];
}
