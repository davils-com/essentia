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
