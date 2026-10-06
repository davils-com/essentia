/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/stream/stream_distinctness.dart';
import 'package:test/test.dart';

/// Checks `distinctUntilChangedBy`.
void main() {
  test('drops consecutive elements with the same key', () async {
    final stream = Stream<String>.fromIterable(<String>['a', 'b', 'cc', 'd']);

    final List<String> distinct = await stream
        .distinctUntilChangedBy((word) => word.length)
        .toList();

    expect(distinct, <String>['a', 'cc', 'd']);
  });

  test('emits a key again once another key came between', () async {
    final stream = Stream<String>.fromIterable(<String>['a', 'bb', 'c']);

    final List<String> distinct = await stream
        .distinctUntilChangedBy((word) => word.length)
        .toList();

    expect(distinct, <String>['a', 'bb', 'c']);
  });
}
