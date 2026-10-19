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

import 'dart:io';

import 'package:essentia_core/essentia_core.dart';
import 'package:test/test.dart';

import 'failure_of.dart';
import 'path_default_parameters.dart';

/// No environment at all.
const _nothing = <String, String>{};

/// A directory that exists.
final String _existing = Directory.systemTemp.path;

/// A path that does not exist.
final _missing =
    '${Directory.systemTemp.path}/essentia-default-that-does-not-exist-7f3a';

/// Tests that a declared path or file default is held to the checks its
/// conversion installed, which only a platform with `dart:io` can make.
void main() {
  group('a path', () {
    test('refuses a default that does not exist when it must', () {
      final ConversionFailure violation = singleViolation<ConversionFailure>(
        failureOf(
          () => PathDefaultParameters(
            _missing,
            _existing,
          ).load(const <String>[], environment: _nothing),
        ),
      );

      expect(violation.origin, ValueOrigin.defaulted);
      expect(violation.reason, 'does not exist');
    });

    test('accepts a default that satisfies every check', () {
      final parameters = PathDefaultParameters(_existing, _existing)
        ..load(const <String>[], environment: _nothing);

      expect(parameters.dataDir.value, _existing);
    });

    test('still checks a value that is given', () {
      final ConversionFailure violation = singleViolation<ConversionFailure>(
        failureOf(
          () => PathDefaultParameters(
            _existing,
            _existing,
          ).load(<String>['--data-dir=$_missing'], environment: _nothing),
        ),
      );

      expect(violation.origin, ValueOrigin.commandLine);
      expect(violation.reason, 'does not exist');
    });
  });

  group('a file', () {
    test('refuses a default that does not exist when it must', () {
      final ConversionFailure violation = singleViolation<ConversionFailure>(
        failureOf(
          () => PathDefaultParameters(
            _existing,
            _missing,
          ).load(const <String>[], environment: _nothing),
        ),
      );

      expect(violation.path.toString(), '--config (default)');
      expect(violation.reason, 'does not exist');
    });

    test('still converts a given value to a file', () {
      final parameters = PathDefaultParameters(_existing, _missing)
        ..load(<String>['--config=$_existing'], environment: _nothing);

      expect(parameters.config.value.path, _existing);
    });
  });
}
