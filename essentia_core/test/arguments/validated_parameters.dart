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
  final Parameter<int?> port = parameter(<String>['--port'])
      .integer()
      .validate((it, value) {
        if (value < _lowestPort || value > _highestPort) {
          it.fail('must be a valid TCP port');
        }
      });

  /// A name checked by two rules.
  final Parameter<String?> name = parameter(<String>['--name'])
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
  final Parameter<List<int>> weights = parameter(<String>['--weight'])
      .integer()
      .multiple()
      .validate((it, value) {
        if (value < 0) {
          it.fail('must not be negative');
        }
      });

  /// A thread count with a rule that fails and a rule that only warns.
  final Parameter<int?> threads = parameter(<String>['--threads'])
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
