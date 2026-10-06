/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

/// A schema whose values have to satisfy rules declared for them.
final class ValidatedParameters extends Parameters {
  /// The lowest port number.
  static const _lowestPort = 1;

  /// The highest port number.
  static const _highestPort = 65535;

  /// The longest name accepted.
  static const _longestName = 8;

  /// The most threads that are not suspicious.
  static const _manyThreads = 256;

  /// A port number.
  late final Parameter<int?> port = parameter(<String>['--port'])
      .integer()
      .validate((it, value) {
        if (value < _lowestPort || value > _highestPort) {
          it.fail('must be a valid TCP port');
        }
      });

  /// A name checked by two rules.
  late final Parameter<String?> name = parameter(<String>['--name'])
      .validate((it, value) {
        if (value.trim().isEmpty) {
          it.fail('must not be blank');
        }
      })
      .validate((it, value) {
        if (value.length > _longestName) {
          it.fail('must be at most 8 characters');
        }
      });

  /// Weights, each checked on its own.
  late final Parameter<List<int>> weights = parameter(<String>['--weight'])
      .integer()
      .multiple()
      .validate((it, value) {
        if (value < 0) {
          it.fail('must not be negative');
        }
      });

  /// A thread count with a rule that fails and a rule that only warns.
  late final Parameter<int?> threads = parameter(<String>['--threads'])
      .integer()
      .validate((it, value) {
        if (value < 0) {
          it.fail('must not be negative');
        }
      })
      .validate((it, value) {
        if (value < 0 || value > _manyThreads) {
          it.warn('is unusually high');
        }
      });

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    port,
    name,
    weights,
    threads,
  ];
}
