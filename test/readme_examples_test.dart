/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
import 'package:test/test.dart';

import 'support/topics.dart';
import 'support/user_event.dart';

/// Runs the version, principal, text and time examples of the README, so
/// that they stay true.
void main() {
  test('the semantic version example', () {
    final version = SemanticVersion.parse('1.4.0-rc.1');
    final range = SemanticVersionRange.parse('^1.2 || >=2.0.0 <2.1.0');

    expect(range.contains(version), isTrue);
    expect(range.contains(version, PreReleasePolicy.sameCoreOnly), isFalse);
    expect(version.nextMinor(), SemanticVersion.parse('1.4.0'));
    expect('1.2.3'.toSemanticVersionOrNull(), SemanticVersion.parse('1.2.3'));
  });

  test('the principal example', () async {
    final Principal alice = principal(
      'alice',
      (it) => it.roles(<String>['admin']),
    );
    final EventBus bus = eventBus((it) => it.topic(users));
    final seen = <String?>[];
    bus.topic(users).subscribe((_) => seen.add(currentPrincipal()?.id));

    await runAsPrincipal(alice, () async {
      expect(requirePrincipal().hasRole('admin'), isTrue);
      await bus.topic(users).publish(const Registered('u-42'));
    });
    await Future<void>.delayed(Duration.zero);
    await bus.drain();

    expect(seen, <String?>['alice']);
  });

  test('the text and time examples', () {
    expect('HTTPServer'.toSnakeCase(), 'http_server');
    expect('lease_duration'.toCamelCase(), 'leaseDuration');
    expect('--prot'.closestIn(<String>['--port', '--host']), '--port');
    expect('PT1H30M'.toIsoDuration(), const Duration(hours: 1, minutes: 30));
    expect(Platform.parse('linux-x86_64').isLinux, isTrue);
  });
}
