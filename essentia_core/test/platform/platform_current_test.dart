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

@TestOn('vm')
library;

import 'dart:io' as io;

import 'package:essentia_core/essentia_core.dart';
import 'package:test/test.dart';

/// The operating systems a desktop test machine runs.
const _desktops = <String>{'linux', 'macos', 'windows'};

/// The architecture the Dart VM reports in its version string, `x64` in
/// `on "linux_x64"`.
///
/// Returns the architecture as the VM spells it, or an empty string when
/// the version string does not carry one.
String _vmArchitecture() {
  final RegExpMatch? match = RegExp('on "[a-z]+_([a-z0-9]+)"')
      .firstMatch(io.Platform.version);
  return match?.group(1) ?? '';
}

/// Tests the platform the Dart VM resolves for the machine running the test.
void main() {
  test('the current machine resolves to what this VM reports about it', () {
    final Platform? current = Platform.current();
    final Platform? expected = Platform.of(
      io.Platform.operatingSystem,
      _vmArchitecture(),
    );

    expect(current, expected);
  });

  test('a 64-bit desktop machine is always named', () {
    final bool isDesktop = _desktops.contains(io.Platform.operatingSystem);
    final isNamedArchitecture = Architecture.resolve(_vmArchitecture()) != null;

    expect(isDesktop, isTrue);
    expect(Platform.current() != null, isNamedArchitecture);
  }, testOn: 'linux || mac-os || windows');

  test('the operating system is the one dart:io reports', () {
    expect(
      Platform.current()?.operatingSystem.identifier,
      io.Platform.operatingSystem,
    );
  });

  test('a desktop VM is never reported as Android, iOS or the web', () {
    expect(Platform.current()?.isAndroid, isFalse);
    expect(Platform.current()?.isIos, isFalse);
    expect(Platform.current()?.isWeb, isFalse);
    expect(Platform.current()?.architecture, isNot(Architecture.wasm));
  }, testOn: 'linux || mac-os || windows');

  test('the predicates agree with the operating system', () {
    final Platform? current = Platform.current();

    expect(current?.isLinux, io.Platform.isLinux);
    expect(current?.isMacos, io.Platform.isMacOS);
    expect(current?.isWindows, io.Platform.isWindows);
    expect(current?.isUnix, !io.Platform.isWindows);
  }, testOn: 'linux || mac-os || windows');

  test('the identifier is one of the identifiers of the table', () {
    expect(Platform.identifiers, contains(Platform.current()?.identifier));
    expect(Platform.entries, contains(Platform.current()));
  }, testOn: 'linux || mac-os || windows');
}
