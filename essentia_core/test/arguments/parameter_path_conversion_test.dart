/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

@TestOn('vm')
library;

import 'dart:io';

import 'package:essentia_core/essentia_core.dart';
import 'package:test/test.dart';

import 'failure_of.dart';
import 'path_parameters.dart';

/// No environment at all.
const _nothing = <String, String>{};

/// Creates an empty directory that is deleted once the running test ended.
///
/// Returns the directory.
Directory _temporaryDirectory() {
  final Directory temporary = Directory.systemTemp.createTempSync(
    'essentia-parameters',
  );
  addTearDown(() => temporary.deleteSync(recursive: true));
  return temporary;
}

/// Tests the conversions that check the file system, which only a platform
/// with `dart:io` has.
void main() {
  group('path conversion', () {
    test('accepts a directory that is there', () {
      final Directory temporary = _temporaryDirectory();
      final parameters = PathParameters()
        ..load(<String>['--dir=${temporary.path}'], environment: _nothing);

      expect(parameters.directory.value, temporary.path);
    });

    test('reports a missing path in the same report as everything else', () {
      final Directory temporary = _temporaryDirectory();
      final ConversionFailure violation = singleViolation<ConversionFailure>(
        failureOf(
          () => PathParameters().load(<String>[
            '--dir=${temporary.path}/missing',
          ], environment: _nothing),
        ),
      );

      expect(violation.reason, 'does not exist');
    });

    test('reports a file where a directory is expected', () {
      final Directory temporary = _temporaryDirectory();
      final file = File('${temporary.path}/plain.txt')..writeAsStringSync('x');

      final ConversionFailure violation = singleViolation<ConversionFailure>(
        failureOf(
          () => PathParameters().load(<String>[
            '--dir=${file.path}',
          ], environment: _nothing),
        ),
      );

      expect(violation.reason, 'is not a directory');
    });

    test('converts a regular file to a file', () {
      final Directory temporary = _temporaryDirectory();
      final file = File('${temporary.path}/plain.txt')..writeAsStringSync('x');

      final parameters = PathParameters()
        ..load(<String>['--file=${file.path}'], environment: _nothing);

      expect(parameters.file.value?.path, file.path);
    });

    test('reports a directory where a regular file is expected', () {
      final Directory temporary = _temporaryDirectory();
      final ConversionFailure violation = singleViolation<ConversionFailure>(
        failureOf(
          () => PathParameters().load(<String>[
            '--file=${temporary.path}',
          ], environment: _nothing),
        ),
      );

      expect(violation.reason, 'is not a regular file');
    });

    test('accepts something that can be read', () {
      final Directory temporary = _temporaryDirectory();
      final parameters = PathParameters()
        ..load(<String>['--readable=${temporary.path}'], environment: _nothing);

      expect(parameters.readable.value, temporary.path);
    });

    test('reports something that cannot be read because it is missing', () {
      final Directory temporary = _temporaryDirectory();
      final ConversionFailure violation = singleViolation<ConversionFailure>(
        failureOf(
          () => PathParameters().load(<String>[
            '--readable=${temporary.path}/missing',
          ], environment: _nothing),
        ),
      );

      expect(violation.reason, 'does not exist');
    });
  });
}
