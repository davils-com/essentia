/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

@TestOn('dart2wasm')
library;

import 'package:essentia_core/essentia_core.dart';
import 'package:test/test.dart';

/// Tests the platform a program compiled to WebAssembly resolves.
void main() {
  test('a WebAssembly module knows it is on the web without asking the '
      'host', () {
    final Platform? current = Platform.current();

    expect(current, isNotNull);
    expect(current?.isWeb, isTrue);
    expect(current?.operatingSystem, OperatingSystem.web);
    expect(current?.architecture, Architecture.wasm);
    expect(current?.identifier, 'web-wasm');
  });

  test('the web is not Unix and is not any of the desktops', () {
    final Platform? current = Platform.current();

    expect(current, isNotNull);
    expect(current?.isUnix, isFalse);
    expect(current?.isLinux, isFalse);
    expect(current?.isMacos, isFalse);
    expect(current?.isWindows, isFalse);
    expect(current?.isAndroid, isFalse);
    expect(current?.isIos, isFalse);
  });
}
