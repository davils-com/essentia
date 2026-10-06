/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:io';

import 'package:essentia/arguments.dart';
import 'package:test/test.dart';

import 'colour.dart';
import 'failure_of.dart';
import 'path_parameters.dart';
import 'typed_parameters.dart';

/// No environment at all.
const _nothing = <String, String>{};

/// Loads [argv] into a new schema.
///
/// Returns the loaded schema.
TypedParameters _load(List<String> argv) =>
    TypedParameters()..load(argv, environment: _nothing);

/// Loads [argv] into a new schema, expecting it to fail.
///
/// Returns the failure.
ParameterException _failure(List<String> argv) => failureOf(() => _load(argv));

/// Tests the conversions Essentia ships and the escape hatch for others.
void main() {
  test('converts the primitive types', () {
    final TypedParameters parameters = _load(<String>[
      '--count=7',
      '--size=9000000000',
      '--ratio=1.5',
      '--enabled=yes',
    ]);

    expect(parameters.count.value, 7);
    expect(parameters.size.value, 9000000000);
    expect(parameters.ratio.value, 1.5);
    expect(parameters.enabled.value, isTrue);
  });

  test('reads every accepted spelling of a boolean', () {
    for (final raw in <String>['true', 'TRUE', 'yes', 'on', '1']) {
      expect(_load(<String>['--enabled=$raw']).enabled.value, isTrue);
    }
    for (final raw in <String>['false', 'no', 'off', '0']) {
      expect(_load(<String>['--enabled=$raw']).enabled.value, isFalse);
    }
  });

  test('rejects a boolean spelling it does not know', () {
    singleViolation<ConversionFailure>(_failure(<String>['--enabled=perhaps']));
  });

  test('matches an enum constant regardless of capitalisation', () {
    expect(_load(<String>['--colour=GREEN']).colour.value, Colour.green);
  });

  test('an unmatched enum value is reported with the ones that would work', () {
    final ConversionFailure violation = singleViolation<ConversionFailure>(
      _failure(<String>['--colour=mauve']),
    );

    expect(violation.reason, contains('red'));
    expect(violation.reason, contains('blue'));
  });

  test('reads an application mode', () {
    expect(
      _load(<String>['--mode=staging']).mode.value,
      ApplicationMode.staging,
    );
  });

  test('rejects a value that is not an application mode', () {
    final ConversionFailure violation = singleViolation<ConversionFailure>(
      _failure(<String>['--mode=chaos']),
    );

    expect(violation.reason, contains('development, test, staging'));
  });

  test('reads a duration in both the readable and the ISO form', () {
    expect(
      _load(<String>['--timeout=30s']).timeout.value,
      const Duration(seconds: 30),
    );
    expect(
      _load(<String>['--timeout=PT5M']).timeout.value,
      const Duration(minutes: 5),
    );
  });

  test('rejects a duration it cannot read', () {
    singleViolation<ConversionFailure>(_failure(<String>['--timeout=soon']));
  });

  test('reads a URI', () {
    expect(
      _load(<String>['--endpoint=https://davils.com/api']).endpoint.value,
      Uri.parse('https://davils.com/api'),
    );
  });

  test('rejects a value that is not a URI', () {
    singleViolation<ConversionFailure>(
      _failure(<String>['--endpoint=http://[']),
    );
  });

  test('restricts a choice to what was declared', () {
    expect(_load(<String>['--level=high']).level.value, 'high');
    singleViolation<ConversionFailure>(_failure(<String>['--level=medium']));
  });

  test('splits one occurrence into several values', () {
    expect(_load(<String>['--tags=a,b', '--tags=c']).tags.value, <String>[
      'a',
      'b',
      'c',
    ]);
  });

  test('leaves an absent split parameter empty', () {
    expect(_load(const <String>[]).tags.value, isEmpty);
  });

  test('reports the parameter and the value it could not convert', () {
    final ConversionFailure violation = singleViolation<ConversionFailure>(
      _failure(<String>['--count=eighty']),
    );

    expect(violation.parameter.primaryName, '--count');
    expect(violation.value, 'eighty');
    expect(violation.reason, 'is not a valid integer');
    expect(violation.code, ParameterViolationCodes.conversionFailed);
    expect(violation.origin, isA<CommandLineOrigin>());
  });

  group('path conversion', () {
    late Directory temporary;

    setUp(() {
      temporary = Directory.systemTemp.createTempSync('essentia-parameters');
    });

    tearDown(() {
      temporary.deleteSync(recursive: true);
    });

    test('accepts a directory that is there', () {
      final parameters = PathParameters()
        ..load(<String>['--dir=${temporary.path}'], environment: _nothing);

      expect(parameters.directory.value, temporary.path);
    });

    test('reports a missing path in the same report as everything else', () {
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
      final file = File('${temporary.path}/plain.txt')..writeAsStringSync('x');

      final parameters = PathParameters()
        ..load(<String>['--file=${file.path}'], environment: _nothing);

      expect(parameters.file.value?.path, file.path);
    });

    test('reports a directory where a regular file is expected', () {
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
      final parameters = PathParameters()
        ..load(<String>['--readable=${temporary.path}'], environment: _nothing);

      expect(parameters.readable.value, temporary.path);
    });

    test('reports something that cannot be read because it is missing', () {
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

  group('a converter the schema brings itself', () {
    test('is applied', () {
      expect(_load(<String>['--id=id-42']).identifier.value, '42');
    });

    test('reports what it rejected', () {
      final ConversionFailure violation = singleViolation<ConversionFailure>(
        _failure(<String>['--id=42']),
      );

      expect(violation.reason, "must start with 'id-'");
      expect(violation.value, '42');
    });

    test('is named in the usage listing by its type name', () {
      expect(TypedParameters().usage(), contains('--id <identifier>'));
    });
  });
}
