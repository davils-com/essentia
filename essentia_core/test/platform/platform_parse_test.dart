/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:test/test.dart';

/// Texts that are not the exact identifier of a platform.
const _refused = <String>[
  '',
  'linux',
  'Linux-x86_64',
  'linux-amd64',
  ' linux-x86_64',
  'linux-x86_64 ',
  'linux_x86_64',
  'freebsd-x86_64',
];

/// Covers reading a platform from its identifier.
void main() {
  test('reads back the identifier of every platform', () {
    final List<Platform> read = Platform.entries
        .map((platform) => Platform.parse(platform.identifier))
        .toList();

    expect(read, Platform.entries);
  });

  test('reads an identifier to the system and architecture it names', () {
    final Platform platform = Platform.parse('macos-aarch64');

    expect(platform.operatingSystem, OperatingSystem.macos);
    expect(platform.architecture, Architecture.aarch64);
  });

  for (final String text in _refused) {
    test('refuses "$text"', () {
      final Platform? platform = Platform.tryParse(text);

      expect(platform, isNull);
    });
  }

  test('a refusal does not quote the text', () {
    const text = 'secret-machine';

    expect(
      () => Platform.parse(text),
      throwsA(
        isA<FormatException>().having(
          (failure) => failure.message,
          'message',
          isNot(contains(text)),
        ),
      ),
    );
  });
}
