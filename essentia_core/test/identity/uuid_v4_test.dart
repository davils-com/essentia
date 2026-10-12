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

/// The canonical text form of a version 4 identifier.
final _textForm = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

/// Tests the random identifier.
void main() {
  test('a minted identifier has the canonical version 4 text form', () {
    expect(UuidV4.random().toString(), matches(_textForm));
  });

  test('two identifiers are never the same', () {
    final minted = List<UuidV4>.generate(1000, (_) => UuidV4.random());

    expect(minted.toSet(), hasLength(minted.length));
  });

  test('identifiers do not arrive in the order they were minted', () {
    final minted = List<UuidV4>.generate(500, (_) => UuidV4.random());
    final sorted = List<UuidV4>.of(minted)..sort();

    expect(sorted, isNot(orderedEquals(minted)));
  });

  test('an identifier reads back from its text form as itself', () {
    final minted = UuidV4.random();

    expect(UuidV4.parse(minted.toString()), minted);
    expect(UuidV4.parse(minted.toString().toUpperCase()), minted);
  });
}
