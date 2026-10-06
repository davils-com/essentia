/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

/// A schema whose ports fall back to defaults that are checked by the same
/// rule as a given value.
final class DefaultedPortParameters extends Parameters {
  /// Creates the schema falling back to [_portDefault] for `--port` and to
  /// [_portsDefault] for `--ports`.
  DefaultedPortParameters(this._portDefault, this._portsDefault);

  /// The lowest port number.
  static const _lowestPort = 1;

  /// The highest port number.
  static const _highestPort = 65535;

  /// The default of `--port`.
  final int _portDefault;

  /// The default of `--ports`.
  final List<int> _portsDefault;

  /// A single port with a default.
  late final Parameter<int> port = parameter(<String>['--port'])
      .integer()
      .validate(_checkPort)
      .defaultsTo(_portDefault);

  /// Several ports with a default list.
  late final Parameter<List<int>> ports = parameter(<String>['--ports'])
      .integer()
      .validate(_checkPort)
      .multiple()
      .defaultsTo(_portsDefault);

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
