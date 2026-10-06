/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
import 'package:test/test.dart';

import 'failure_of.dart';
import 'lenient_parameters.dart';
import 'syntax_parameters.dart';

/// No environment at all.
const _nothing = <String, String>{};

/// Loads [argv] into a new schema.
///
/// Returns the loaded schema.
SyntaxParameters _load(List<String> argv) =>
    SyntaxParameters()..load(argv, environment: _nothing);

/// Loads [argv] into a new schema, expecting it to fail.
///
/// Returns the failure.
ParameterException _failure(List<String> argv) => failureOf(() => _load(argv));

/// Tests how a command line is read.
void main() {
  test('reads a long parameter written with an equals sign', () {
    expect(_load(<String>['--name=arc']).name.value, 'arc');
  });

  test('reads a long parameter whose value is the next token', () {
    expect(_load(<String>['--name', 'arc']).name.value, 'arc');
  });

  test('reads a short parameter whose value is the next token', () {
    expect(_load(<String>['-n', 'arc']).name.value, 'arc');
  });

  test('reads a short parameter with an attached value', () {
    expect(_load(<String>['-narc']).name.value, 'arc');
  });

  test('reads a short parameter written with an equals sign', () {
    expect(_load(<String>['-n=arc']).name.value, 'arc');
  });

  test('splits a value at the first equals sign only', () {
    expect(_load(<String>['--name=a=b=c']).name.value, 'a=b=c');
  });

  test('accepts an empty value', () {
    expect(_load(<String>['--name=']).name.value, '');
  });

  test('a lone dash is a value', () {
    expect(_load(<String>['--name', '-']).name.value, '-');
  });

  test('a flag that is named is true', () {
    expect(_load(<String>['--verbose']).verbose.value, isTrue);
  });

  test('a flag that is not named is false', () {
    expect(_load(const <String>[]).verbose.value, isFalse);
  });

  test('a flag accepts an explicit value', () {
    expect(_load(<String>['--verbose=false']).verbose.value, isFalse);
  });

  test('a short flag accepts an explicit value', () {
    expect(_load(<String>['-v=false']).verbose.value, isFalse);
  });

  test('a flag given a value it cannot read is reported', () {
    singleViolation<ConversionFailure>(_failure(<String>['--verbose=maybe']));
  });

  test('clustered short flags each turn on', () {
    final SyntaxParameters parameters = _load(<String>['-va']);

    expect(parameters.verbose.value, isTrue);
    expect(parameters.archive.value, isTrue);
  });

  test('a clustered run may end in a parameter that takes a value', () {
    final SyntaxParameters parameters = _load(<String>['-van', 'arc']);

    expect(parameters.verbose.value, isTrue);
    expect(parameters.archive.value, isTrue);
    expect(parameters.name.value, 'arc');
  });

  test('a clustered run may end in an attached value', () {
    final SyntaxParameters parameters = _load(<String>['-vnarc']);

    expect(parameters.verbose.value, isTrue);
    expect(parameters.name.value, 'arc');
  });

  test('an unknown letter in a cluster is reported', () {
    final UnknownArgument violation = singleViolation<UnknownArgument>(
      _failure(<String>['-vx']),
    );

    expect(violation.token, '-x');
  });

  test('a negated flag turns its default off', () {
    expect(_load(<String>['--no-colour']).colour.value, isFalse);
  });

  test('a negatable flag keeps its default when it is not named', () {
    expect(_load(const <String>[]).colour.value, isTrue);
  });

  test('a repeatable parameter collects every occurrence', () {
    expect(
      _load(<String>['--tag=a', '-t', 'b', '--tag', 'c']).tags.value,
      <String>['a', 'b', 'c'],
    );
  });

  test('a repeatable parameter is empty when it is not given', () {
    expect(_load(const <String>[]).tags.value, isEmpty);
  });

  test('everything after the terminator is left untouched', () {
    final SyntaxParameters parameters = _load(<String>[
      '--name=arc',
      '--',
      '--not-mine',
      '-x',
      'plain',
    ]);

    expect(parameters.name.value, 'arc');
    expect(parameters.rest, <String>['--not-mine', '-x', 'plain']);
  });

  test('nothing after the terminator leaves the rest empty', () {
    expect(_load(const <String>[]).rest, isEmpty);
  });

  test('a negative number is read as a value rather than as a parameter', () {
    expect(_load(<String>['--port', '-5']).port.value, -5);
  });

  test('an empty argument list leaves every optional parameter null', () {
    final SyntaxParameters parameters = _load(const <String>[]);

    expect(parameters.name.value, isNull);
    expect(parameters.port.value, isNull);
  });

  test('a parameter that expects a value but ends the list is reported', () {
    final MissingParameterValue violation =
        singleViolation<MissingParameterValue>(_failure(<String>['--name']));

    expect(violation.token, '--name');
    expect(violation.message, contains('string'));
  });

  test('a following parameter is not swallowed as a missing value', () {
    final MissingParameterValue violation =
        singleViolation<MissingParameterValue>(
          _failure(<String>['--name', '--verbose']),
        );

    expect(violation.parameter.primaryName, '--name');
  });

  test('a single valued parameter given twice is reported', () {
    final RepeatedParameter violation = singleViolation<RepeatedParameter>(
      _failure(<String>['--name=first', '--name=second']),
    );

    expect(violation.occurrences, 2);
  });

  test('a token with no name after its dashes is reported as malformed', () {
    final MalformedArgument violation = singleViolation<MalformedArgument>(
      _failure(<String>['--=value']),
    );

    expect(violation.token, '--');
  });

  test('an undeclared parameter is reported with the name it probably was', () {
    final UnknownArgument violation = singleViolation<UnknownArgument>(
      _failure(<String>['--verbsoe']),
    );

    expect(violation.suggestion, '--verbose');
    expect(violation.code, ParameterViolationCodes.unknownArgument);
  });

  test('an undeclared parameter close to nothing suggests nothing', () {
    final UnknownArgument violation = singleViolation<UnknownArgument>(
      _failure(<String>['--something-entirely-different']),
    );

    expect(violation.suggestion, isNull);
    expect(violation.message, 'is not a known parameter');
  });

  test('a bare positional argument is reported by where it was', () {
    final StrayValue violation = singleViolation<StrayValue>(
      _failure(<String>['stray']),
    );

    expect(violation.position, 1);
  });

  test('every problem of one command line is reported together', () {
    final ParameterException failure = _failure(<String>[
      '--verbsoe',
      'stray',
      '--port=x',
      '--name',
    ]);

    expect(failure.violations, hasLength(4));
  });

  test('an undeclared parameter is collected instead of rejected', () {
    final parameters = LenientParameters()
      ..load(<String>[
        '--name=arc',
        '--theirs',
        'stray',
      ], environment: _nothing);

    expect(parameters.name.value, 'arc');
    expect(parameters.unknown, <String>['--theirs', 'stray']);
  });

  test('nothing is collected under the default policy', () {
    expect(_load(<String>['--name=arc']).unknown, isEmpty);
  });
}
