/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:test/test.dart';

import '../support/topics.dart';
import '../support/user_event.dart';

/// The largest buffer a partition may have.
const _largestBuffer = 1048576;

/// The most envelopes a topic may replay.
const _largestReplay = 1048576;

/// The most partitions a topic may have.
const _mostPartitions = 1024;

/// The largest value of a Kotlin `Int`, which Arc refuses because a channel
/// reads it as unbounded, and which is simply over every ceiling here.
const _kotlinIntMax = 2147483647;

/// Declares a bus carrying the user topic configured by [block], without
/// starting it.
///
/// Returns the builder, ready to be validated.
EventBusBuilder _declare(
  void Function(EventTopicBuilder<UserEvent> it) block,
) => EventBusBuilder()..topic(users, block);

/// Tests the ceilings on what a topic may be declared to hold.
void main() {
  test('a buffer of the largest Kotlin Int is refused, because it is over '
      'the ceiling', () {
    final ValidationReport report = _declare(
      (it) => it.bufferCapacity = _kotlinIntMax,
    ).validate();

    expect(report.isValid, isFalse);
    expect(report.errors.single.code, EventViolationCodes.invalidBuffer);
    expect(report.errors.single.path.toString(), 'topics[0].bufferCapacity');
  });

  test('a buffer one over the ceiling is refused and one at it is '
      'allowed', () {
    final ValidationReport over = _declare(
      (it) => it.bufferCapacity = _largestBuffer + 1,
    ).validate();
    final ValidationReport at = _declare(
      (it) => it.bufferCapacity = _largestBuffer,
    ).validate();

    expect(over.errors.single.code, EventViolationCodes.invalidBuffer);
    expect(at.isValid, isTrue);
  });

  test('partitions over the ceiling are refused and at it are allowed', () {
    final ValidationReport over = _declare(
      (it) => it.partitions = _mostPartitions + 1,
    ).validate();
    final ValidationReport at = _declare(
      (it) => it.partitions = _mostPartitions,
    ).validate();

    expect(over.errors.single.code, EventViolationCodes.invalidPartitions);
    expect(at.isValid, isTrue);
  });

  test('replay over the ceiling is refused and at it is allowed', () {
    final ValidationReport over = _declare(
      (it) => it.replay = _largestReplay + 1,
    ).validate();
    final ValidationReport at = _declare((it) => it.replay = _largestReplay)
        .validate();

    expect(over.errors.single.code, EventViolationCodes.invalidReplay);
    expect(at.isValid, isTrue);
  });

  test('every dimension over its ceiling is reported at once', () {
    final ValidationReport report = _declare((it) {
      it
        ..replay = _kotlinIntMax
        ..bufferCapacity = _kotlinIntMax
        ..partitions = _kotlinIntMax;
    }).validate();

    expect(report.errors.map((error) => error.path.toString()), <String>[
      'topics[0].replay',
      'topics[0].bufferCapacity',
      'topics[0].partitions',
    ]);
  });
}
