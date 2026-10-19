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
