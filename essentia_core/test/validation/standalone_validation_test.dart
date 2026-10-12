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

import 'form_slot.dart';
import 'workspace_form.dart';

/// Three slots, one more than is usual.
const _threeSlots = <FormSlot>[
  FormSlot('a', 1),
  FormSlot('b', 1),
  FormSlot('c', 1),
];

/// Ports `StandaloneValidationTest`.
void main() {
  test('a value with nothing wrong reports nothing', () {
    final ValidationReport report = const WorkspaceForm().validateAs(
      'workspace',
    );

    expect(report.isValid, isTrue);
    expect(report.violations, isEmpty);
  });

  test('every rule runs, so three problems are reported once', () {
    final ValidationReport report = const WorkspaceForm(
      name: '',
      owner: '',
      slots: <FormSlot>[FormSlot('first', 0)],
    ).validateAs('workspace');

    expect(
      report.errors.map((violation) => violation.path.toString()).toList(),
      <String>['name', 'owner', 'slots[0].size'],
    );
  });

  test('the subject names what was validated in the headline', () {
    final ValidationReport report = const WorkspaceForm(name: '')
        .validateAs('workspace');

    expect(report.render(), contains('Invalid workspace (1 problem):'));
  });

  test('a warning does not make a value unusable', () {
    final ValidationReport report = const WorkspaceForm(slots: _threeSlots)
        .validateAs('workspace');

    expect(report.isValid, isTrue);
    expect(report.warnings, hasLength(1));
    expect(report.warnings.single.code, WorkspaceForm.tooManySlots);
  });

  test('validateOrThrow hands the value back so the boundary reads as one '
      'step', () {
    const valid = WorkspaceForm();

    expect(valid.validateOrThrow('workspace'), same(valid));
  });

  test('validateOrThrow does not throw over warnings alone', () {
    const warned = WorkspaceForm(slots: _threeSlots);

    expect(() => warned.validateOrThrow('workspace'), returnsNormally);
  });

  test('validateOrThrow carries the whole report, not the first problem', () {
    expect(
      () =>
          const WorkspaceForm(name: '', owner: '').validateOrThrow('workspace'),
      throwsA(
        isA<ValidationException>()
            .having((failure) => failure.report.errors, 'errors', hasLength(2))
            .having((failure) => failure.message, 'message', contains('name'))
            .having((failure) => failure.message, 'message', contains('owner')),
      ),
    );
  });
}
