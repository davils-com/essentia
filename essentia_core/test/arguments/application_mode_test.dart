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

/// Tests looking an application mode up by the name it is written as.
void main() {
  test('every mode is found by the name it is written as', () {
    for (final ApplicationMode mode in ApplicationMode.values) {
      expect(ApplicationMode.byValue(mode.value), mode);
    }
  });

  test('lookup ignores capitalisation', () {
    expect(ApplicationMode.byValue('PRODUCTION'), ApplicationMode.production);
    expect(ApplicationMode.byValue('Staging'), ApplicationMode.staging);
  });

  test('an unknown name yields null rather than an exception', () {
    expect(ApplicationMode.tryByValue('chaos'), isNull);
  });

  test('the throwing lookup lists what would have worked', () {
    expect(
      () => ApplicationMode.byValue('chaos'),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.toString(),
          'text',
          contains('development, test, staging, production'),
        ),
      ),
    );
  });

  test('the throwing lookup does not quote what it was given', () {
    const placeholder = 'placeholder-not-a-mode';

    expect(
      () => ApplicationMode.byValue(placeholder),
      throwsA(
        isA<ArgumentError>()
            .having((error) => error.invalidValue, 'invalidValue', isNull)
            .having(
              (error) => error.toString(),
              'text',
              isNot(contains(placeholder)),
            ),
      ),
    );
  });

  test('a mode renders as the name it is written as', () {
    expect(ApplicationMode.development.toString(), 'development');
  });

  test('the two shorthand checks answer for the modes they name', () {
    expect(ApplicationMode.development.isDevelopment, isTrue);
    expect(ApplicationMode.development.isProduction, isFalse);
    expect(ApplicationMode.production.isProduction, isTrue);
    expect(ApplicationMode.staging.isDevelopment, isFalse);
  });
}
