/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:math';

import 'package:test/test.dart';

import 'assignment.dart';
import 'spelling_parameters.dart';

/// How many cases each property is checked against.
const _cases = 300;

/// No environment at all.
const _nothing = <String, String>{};

/// Loads [argv] into a new schema.
///
/// Returns the loaded schema.
SpellingParameters _load(List<String> argv) =>
    SpellingParameters()..load(argv, environment: _nothing);

/// Tests that every legal spelling of the same values resolves to them.
void main() {
  test('every legal spelling of an assignment resolves back to it', () {
    final random = Random(31);
    for (var round = 0; round < _cases; round++) {
      final assignment = Assignment.random(random);
      final List<String> argv = assignment.render();
      final String clue = argv.join(' ');

      final SpellingParameters parameters = _load(argv);

      expect(parameters.host.value, assignment.host, reason: clue);
      expect(parameters.port.value, assignment.port, reason: clue);
      expect(parameters.verbose.value, assignment.verbose, reason: clue);
      expect(parameters.archive.value, assignment.archive, reason: clue);
      expect(parameters.colour.value, assignment.colour, reason: clue);
      expect(parameters.tags.value, assignment.tags, reason: clue);
      expect(parameters.rest, assignment.trailing, reason: clue);
    }
  });

  test('an attached value and a separated value are the same argument', () {
    final random = Random(32);
    for (var round = 0; round < _cases; round++) {
      final assignment = Assignment.random(random);

      final SpellingParameters attached = _load(
        assignment.respelt(useAttachedValues: true).render(),
      );
      final SpellingParameters separated = _load(
        assignment.respelt(useAttachedValues: false).render(),
      );

      expect(attached.describe(), separated.describe());
    }
  });

  test('a long form and a short form are the same argument', () {
    final random = Random(33);
    for (var round = 0; round < _cases; round++) {
      final assignment = Assignment.random(random);

      final SpellingParameters long = _load(
        assignment.respelt(useShortForms: false).render(),
      );
      final SpellingParameters short = _load(
        assignment.respelt(useShortForms: true).render(),
      );

      expect(long.describe(), short.describe());
    }
  });
}
