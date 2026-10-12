/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_time/essentia_time.dart';
import 'package:test/test.dart';

/// Uses the extensions through the public library, so that two exported
/// extensions claiming the same member on related types fail to compile
/// here instead of in a consumer.
void main() {
  test('list members win over the iterable members of the same name', () {
    expect(<int>[1, 2, 3].takeLast(2), <int>[2, 3]);
    expect(<int>[1, 2, 3].dropLast(1), <int>[1, 2]);
    expect(Iterable<int>.generate(3).takeLast(1), <int>[2]);
  });

  test('set members win over the iterable members of the same name', () {
    expect(<int>{1, 2}.minusElement(1), <int>{2});
    expect(<int>{1, 2}.plusElement(3), <int>{1, 2, 3});
  });

  test('text, number and time members resolve without ambiguity', () {
    expect('abc'.takeLast(2), 'bc');
    expect('abc'.countWhere((character) => character != 'b'), 2);
    expect(<String, int>{'a': 1}.countWhere((_, value) => value > 0), 1);
    expect(7.mod(3), 1);
    expect(2.seconds, const Duration(seconds: 2));
    expect(1.rangeTo(3).toList(), <int>[1, 2, 3]);
    expect(5.coerceAtMost(3), 3);
    expect('port'.let((text) => text.length), 4);
  });

  test('stream members resolve beside their iterable namesakes', () async {
    final numbers = Stream<int>.fromIterable(<int>[1, 2, 3]);

    expect(await numbers.countWhere((number) => number.isOdd), 2);
    expect(<int?>[1, null].mapNotNull((number) => number).toList(), <int>[1]);
  });

  test('a result is reachable through the library', () {
    final Result<int> result = runCatching(() => int.parse('42'));

    expect(result.valueOrNull, 42);
  });

  test('formatting and compression resolve through the library', () async {
    final epoch = Instant.fromEpochSeconds(0);

    expect(epoch.format(DateTimeFormats.isoLocal), '1970-01-01T00:00:00.000');
    expect(await gunzip(await gzip(<int>[1, 2, 3])), <int>[1, 2, 3]);
    expect(Crc32.of(const <int>[]), 0);
  });

  test('byte members resolve beside the list members', () {
    final ByteString bytes = 'ab'.hexToByteString();

    expect(<int>[0xab].toHexString(), 'ab');
    expect(<int>[0xab].contentEquals(bytes.toByteArray()), isTrue);
    expect(<int>[0xab].toByteString(), bytes);
  });
}
