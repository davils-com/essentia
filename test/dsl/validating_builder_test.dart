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

import 'logging_builder.dart';
import 'logging_data.dart';

/// Builds the logging configuration [block] describes.
LoggingData _logging(void Function(LoggingBuilder it) block) =>
    LoggingBuilder().apply(block).build();

/// The rendered paths of everything [report] holds, in order.
List<String> _paths(ValidationReport report) =>
    report.violations.map((violation) => violation.path.toString()).toList();

/// Matches a [ValidationException] whose report satisfies [matcher].
Matcher _throwsReport(Matcher matcher) => throwsA(
  isA<ValidationException>().having(
    (failure) => failure.report,
    'report',
    matcher,
  ),
);

/// Matches a report whose paths are exactly [paths].
Matcher _hasPaths(List<String> paths) =>
    isA<ValidationReport>().having(_paths, 'paths', paths);

/// Ports `ValidatingBuilderTest`.
void main() {
  test('a valid configuration builds', () {
    final LoggingData data = _logging((it) {
      it
        ..sink((it) => it.name = 'console')
        ..sink((it) {
          it
            ..name = 'file'
            ..async((it) => it.queueSize = 4096);
        });
    });

    expect(data.sinks, hasLength(2));
    expect(data.sinks[1].async?.queueSize, 4096);
    expect(data.sinks[0].async, isNull);
  });

  test('problems across two levels of nesting and the parent itself arrive '
      'in one report', () {
    expect(
      () => _logging((it) {
        it
          ..sink((it) => it.name = '')
          ..sink((it) {
            it
              ..name = 'file'
              ..async((it) => it.queueSize = -1);
          });
      }),
      _throwsReport(
        _hasPaths(<String>[
          'sinks[0].name',
          'sinks[1].async.queueSize',
          'sinks',
        ]),
      ),
    );
  });

  test('a nested block does not fail on its own before the rest has been '
      'configured', () {
    expect(
      () => _logging((it) {
        it
          ..sink((it) => it.name = '')
          ..sink((it) => it.name = '')
          ..sink((it) => it.name = '');
      }),
      _throwsReport(
        isA<ValidationReport>().having(
          (report) => report.errors,
          'errors',
          hasLength(4),
        ),
      ),
    );
  });

  test('the index in a path counts declared blocks, not the ones that '
      'survived', () {
    expect(
      () => _logging((it) {
        it
          ..sink((it) => it.name = '')
          ..sink((it) => it.name = 'ok')
          ..sink((it) => it.name = '');
      }),
      _throwsReport(_hasPaths(<String>['sinks[0].name', 'sinks[2].name'])),
    );
  });

  test('a parent rule still sees the nested values that were valid', () {
    expect(
      () => _logging((it) {
        it
          ..sink((it) => it.name = 'console')
          ..sink((it) => it.name = 'console');
      }),
      _throwsReport(
        isA<ValidationReport>().having(
          (report) => report.violations.single,
          'violation',
          isA<Violation>()
              .having((violation) => '${violation.path}', 'path', 'sinks')
              .having(
                (violation) => violation.message,
                'message',
                allOf(contains('must be unique'), contains('console')),
              ),
        ),
      ),
    );
  });

  test('the rendered message names every path', () {
    expect(
      () => _logging((it) {
        it
          ..sink((it) => it.name = '')
          ..sink((it) {
            it
              ..name = 'file'
              ..async((it) => it.queueSize = 0);
          });
      }),
      throwsA(
        isA<ValidationException>().having(
          (failure) => failure.message,
          'message',
          allOf(
            contains('Invalid configuration (3 problems):'),
            contains('sinks[0].name'),
            contains('sinks[1].async.queueSize'),
          ),
        ),
      ),
    );
  });

  test('validate reports the same problems without throwing', () {
    final builder = LoggingBuilder()..sink((it) => it.name = '');

    late ValidationReport report;
    expect(() => report = builder.validate(), returnsNormally);

    expect(report.isValid, isFalse);
    expect(_paths(report), <String>['sinks[0].name', 'sinks']);
  });

  test('a warning alone does not stop the build', () {
    final LoggingData data = _logging((it) {
      it
        ..level = LoggingData.trace
        ..sink((it) => it.name = 'console');
    });

    expect(data.level, LoggingData.trace);
  });

  test('a warning is reported alongside the errors that did stop the '
      'build', () {
    expect(
      () => _logging((it) => it.level = LoggingData.trace),
      throwsA(
        isA<ValidationException>()
            .having((failure) => failure.report.errors, 'errors', hasLength(1))
            .having(
              (failure) => failure.report.warnings.single.severity,
              'warning severity',
              Severity.warning,
            )
            .having(
              (failure) => failure.message,
              'message',
              contains('1 warning:'),
            ),
      ),
    );
  });

  test('a configuration with only warnings is valid and still reports '
      'them', () {
    final ValidationReport report =
        (LoggingBuilder()
              ..level = LoggingData.trace
              ..sink((it) => it.name = 'console'))
            .validate();

    expect(report.isValid, isTrue);
    expect(report.warnings, hasLength(1));
  });

  test('validating does not consume the builder, so build agrees '
      'afterwards', () {
    final builder = LoggingBuilder()..sink((it) => it.name = 'console');

    expect(builder.validate().isValid, isTrue);
    expect(builder.validate().isValid, isTrue);
    expect(builder.build().sinks.single.name, 'console');
  });

  test('the report of a builder is about the configuration', () {
    final ValidationReport report = LoggingBuilder().validate();

    expect(report.subject, 'configuration');
    expect(report.render(), startsWith('Invalid configuration (1 problem):'));
  });
}
