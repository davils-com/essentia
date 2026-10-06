/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// The environment an application considers itself to be running in.
///
/// The mode is a coarse switch for behaviour that has to differ between a
/// developer's machine and a production deployment: how much diagnostic
/// detail to emit, whether to trust a self-signed certificate, whether to
/// seed test data. It is deliberately not a place to hang configuration:
/// anything with a value belongs in a parameter of its own.
enum ApplicationMode {
  /// A developer's machine, where convenience outweighs hardening.
  development('development'),

  /// An automated test run.
  test('test'),

  /// A deployment that mirrors production but is not it.
  staging('staging'),

  /// The real thing.
  production('production');

  /// Creates the mode written as [value].
  const ApplicationMode(this.value);

  /// Returns the mode written as [value], ignoring capitalisation.
  ///
  /// Throws an [ArgumentError] if nothing matches.
  factory ApplicationMode.byValue(String value) =>
      tryByValue(value) ??
      (throw ArgumentError.value(
        value,
        'value',
        'Not an application mode, expected one of ${_written()}',
      ));

  /// The lowercase name the mode is written as.
  final String value;

  /// Whether this is [development].
  bool get isDevelopment => this == development;

  /// Whether this is [production].
  bool get isProduction => this == production;

  /// Looks the mode written as [value] up, ignoring capitalisation.
  ///
  /// Returns the matching mode, or `null` when nothing matches.
  static ApplicationMode? tryByValue(String value) {
    final String wanted = value.toLowerCase();
    for (final ApplicationMode mode in values) {
      if (mode.value == wanted) {
        return mode;
      }
    }
    return null;
  }

  /// Lists every mode the way it is written, for a message.
  ///
  /// Returns the names joined by commas.
  static String _written() => values.map((mode) => mode.value).join(', ');

  /// The lowercase name.
  @override
  String toString() => value;
}
