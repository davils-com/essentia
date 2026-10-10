/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/bytes/compression/gzip_platform_stub.dart';
import 'package:test/test.dart';

/// Covers gzip on a platform with neither `dart:io` nor a browser.
void main() {
  test('fails to compress with an unsupported error', () async {
    await expectLater(
      platformGzip(const Stream<List<int>>.empty(), 6).toList(),
      throwsUnsupportedError,
    );
  });

  test('fails to decompress with an unsupported error', () async {
    await expectLater(
      platformGunzip(const Stream<List<int>>.empty()).toList(),
      throwsUnsupportedError,
    );
  });
}
