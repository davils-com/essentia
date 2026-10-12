/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:test/test.dart';

/// Names what [result] stands for with an exhaustive switch.
///
/// Returns the name.
String _describe(ChannelResult<int> result) => switch (result) {
  ChannelSuccess(:final value) => 'value $value',
  ChannelClosed(:final cause) => 'closed by $cause',
  ChannelFailure() => 'failed',
};

/// Covers the outcome of channel operations that do not wait: success,
/// failure and closure, with Kotlin's accessors.
void main() {
  test('a success carries its value', () {
    const ChannelResult<int> result = ChannelSuccess(7);

    expect(result.isSuccess, isTrue);
    expect(result.isFailure, isFalse);
    expect(result.isClosed, isFalse);
    expect(result.getOrNull(), 7);
    expect(result.getOrThrow(), 7);
    expect(result.exceptionOrNull(), isNull);
    expect(result.toString(), 'ChannelSuccess(7)');
  });

  test('a success may carry null', () {
    const ChannelResult<int?> result = ChannelSuccess<int?>(null);

    expect(result.isSuccess, isTrue);
    expect(result.getOrThrow(), isNull);
  });

  test('a failure carries nothing and refuses to give a value', () {
    const ChannelResult<int> result = ChannelFailure();

    expect(result.isSuccess, isFalse);
    expect(result.isFailure, isTrue);
    expect(result.isClosed, isFalse);
    expect(result.getOrNull(), isNull);
    expect(result.exceptionOrNull(), isNull);
    expect(result.getOrThrow, throwsStateError);
    expect(result.toString(), 'ChannelFailure');
  });

  test('a closed result is a failure carrying its cause', () {
    final cause = Exception('broken');
    final ChannelResult<int> result = ChannelClosed(cause);

    expect(result, isA<ChannelFailure<int>>());
    expect(result.isSuccess, isFalse);
    expect(result.isFailure, isTrue);
    expect(result.isClosed, isTrue);
    expect(result.getOrNull(), isNull);
    expect(result.exceptionOrNull(), same(cause));
    expect(result.getOrThrow, throwsA(same(cause)));
    expect(result.toString(), 'ChannelClosed(Exception: broken)');
  });

  test('a result closed without a cause throws a state error', () {
    const ChannelResult<int> result = ChannelClosed(null);

    expect(result.exceptionOrNull(), isNull);
    expect(result.getOrThrow, throwsStateError);
  });

  test('results are equal by kind and content', () {
    expect(const ChannelSuccess(1), const ChannelSuccess(1));
    expect(const ChannelSuccess(1), isNot(const ChannelSuccess(2)));
    expect(const ChannelSuccess(1).hashCode, const ChannelSuccess(1).hashCode);
    expect(const ChannelFailure<int>(), const ChannelFailure<String>());
    expect(
      const ChannelFailure<int>().hashCode,
      const ChannelFailure<int>().hashCode,
    );
    expect(const ChannelFailure<int>(), isNot(const ChannelClosed<int>(null)));
    expect(const ChannelClosed<int>('a'), const ChannelClosed<int>('a'));
    expect(const ChannelClosed<int>('a'), isNot(const ChannelClosed<int>('b')));
    expect(const ChannelClosed<int>(null), isNot(const ChannelFailure<int>()));
    expect(
      const ChannelClosed<int>('a').hashCode,
      const ChannelClosed<int>('a').hashCode,
    );
    expect(
      const ChannelSuccess<int?>(null),
      isNot(const ChannelFailure<int>()),
    );
  });

  test('an exhaustive switch tells the three kinds apart', () {
    expect(_describe(const ChannelSuccess(3)), 'value 3');
    expect(_describe(const ChannelClosed('done')), 'closed by done');
    expect(_describe(const ChannelFailure()), 'failed');
  });
}
