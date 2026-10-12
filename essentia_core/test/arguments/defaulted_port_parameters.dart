/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
