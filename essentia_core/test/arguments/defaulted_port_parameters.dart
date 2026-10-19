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

/// A schema whose ports fall back to defaults that are checked by the same
/// rule as a given value.
final class DefaultedPortParameters extends Parameters {
  /// Creates the schema falling back to [portDefault] for `--port` and to
  /// [portsDefault] for `--ports`.
  DefaultedPortParameters(int portDefault, List<int> portsDefault)
    : port = parameter(<String>['--port'])
          .integer()
          .validate(_checkPort)
          .defaultsTo(portDefault),
      ports = parameter(<String>['--ports'])
          .integer()
          .validate(_checkPort)
          .multiple()
          .defaultsTo(portsDefault);

  /// The lowest port number.
  static const _lowestPort = 1;

  /// The highest port number.
  static const _highestPort = 65535;

  /// A single port with a default.
  final Parameter<int> port;

  /// Several ports with a default list.
  final Parameter<List<int>> ports;

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[port, ports];

  /// Reports [value] through [it] unless it is a port number.
  static void _checkPort(ValidationScope it, int value) {
    if (value < _lowestPort || value > _highestPort) {
      it.fail('must be a port number');
    }
  }
}
