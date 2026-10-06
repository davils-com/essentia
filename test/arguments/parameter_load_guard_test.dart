/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:test/test.dart';

import 'defaulted_port_parameters.dart';
import 'failure_of.dart';
import 'gated_source.dart';

/// No environment at all.
const _nothing = <String, String>{};

/// A schema with a checked port that falls back to 8080.
///
/// Returns the schema.
DefaultedPortParameters _schema() =>
    DefaultedPortParameters(8080, const <int>[]);

/// Matches a [StateError] refusing a second load.
final Matcher _refusedAsLoaded = throwsA(
  isA<StateError>().having(
    (error) => error.message,
    'message',
    contains('is being loaded'),
  ),
);

/// Tests that a schema is loaded exactly once, even when a load is still
/// waiting for a source.
void main() {
  test('a load while an asynchronous load waits is refused, and the first '
      'one wins', () async {
    final DefaultedPortParameters parameters = _schema();
    final gate = GatedSource();
    final Future<void> first = parameters.loadFrom(
      const <String>[],
      <GatedSource>[gate],
      environment: _nothing,
    );

    expect(
      () => parameters.load(<String>['--port=2'], environment: _nothing),
      _refusedAsLoaded,
    );
    gate.open();
    await first;

    expect(parameters.port.value, 1);
  });

  test('two asynchronous loads at once: exactly one wins', () async {
    final DefaultedPortParameters parameters = _schema();
    final gate = GatedSource();
    final Future<void> first = parameters.loadFrom(
      const <String>[],
      <GatedSource>[gate],
      environment: _nothing,
    );

    await expectLater(
      parameters.loadFrom(const <String>[], <GatedSource>[
        gate,
      ], environment: _nothing),
      _refusedAsLoaded,
    );
    gate.open();
    await first;

    expect(parameters.isLoaded, isTrue);
  });

  test('a load that failed can be retried', () {
    final DefaultedPortParameters parameters = _schema();
    failureOf(
      () => parameters.load(<String>['--port=0'], environment: _nothing),
    );

    parameters.load(<String>['--port=9'], environment: _nothing);

    expect(parameters.port.value, 9);
  });

  test('an asynchronous load that failed can be retried', () async {
    final DefaultedPortParameters parameters = _schema();
    await failureOfAsync(
      () => parameters.loadFrom(
        <String>['--port=0'],
        const <GatedSource>[],
        environment: _nothing,
      ),
    );

    await parameters.loadFrom(
      <String>['--port=9'],
      const <GatedSource>[],
      environment: _nothing,
    );

    expect(parameters.port.value, 9);
  });
}
