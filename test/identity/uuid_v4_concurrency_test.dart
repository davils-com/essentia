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

/// How many tasks mint at once.
const _tasks = 8;

/// How many identifiers each task mints.
const _perTask = 2000;

/// How many identifiers a task mints before it lets the others run.
const _burst = 50;

/// Hands control to the event loop, so that the other tasks get to run.
Future<void> _pause() => Future<void>.delayed(Duration.zero);

/// Mints [_perTask] identifiers in bursts, interleaved with the other tasks,
/// into [shared] and into the list it returns.
Future<List<UuidV4>> _mint(List<UuidV4> shared) async {
  final own = <UuidV4>[];
  for (var index = 0; index < _perTask; index++) {
    final minted = UuidV4.random();
    own.add(minted);
    shared.add(minted);
    if (index % _burst == 0) {
      await _pause();
    }
  }
  return own;
}

/// Tests minting random identifiers from many interleaved tasks.
void main() {
  test('minting from several tasks at once produces no collisions', () async {
    final shared = <UuidV4>[];

    final List<List<UuidV4>> minted = await Future.wait(<Future<List<UuidV4>>>[
      for (var task = 0; task < _tasks; task++) _mint(shared),
    ]);

    final all = <UuidV4>{for (final List<UuidV4> batch in minted) ...batch};
    expect(all, hasLength(_tasks * _perTask));
    expect(shared, hasLength(all.length));
    expect(all.containsAll(shared), isTrue);
  });

  test('a tight loop of many mints produces no collisions', () {
    final minted = <UuidV4>{
      for (var index = 0; index < _tasks * _perTask; index++) UuidV4.random(),
    };

    expect(minted, hasLength(_tasks * _perTask));
  });
}
