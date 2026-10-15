/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/bytes/compression/compression_format.dart';
import 'package:essentia_core/src/bytes/compression/compression_platform_stub.dart';
import 'package:test/test.dart';

/// Covers compression on a platform with neither `dart:io` nor a browser.
void main() {
  test('fails to compress with an unsupported error', () async {
    for (final CompressionFormat format in CompressionFormat.values) {
      await expectLater(
        platformCompress(const Stream<List<int>>.empty(), format, 6).toList(),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            startsWith(format.webName),
          ),
        ),
      );
    }
  });

  test('fails to decompress with an unsupported error', () async {
    for (final CompressionFormat format in CompressionFormat.values) {
      await expectLater(
        platformDecompress(const Stream<List<int>>.empty(), format).toList(),
        throwsUnsupportedError,
      );
    }
  });
}
