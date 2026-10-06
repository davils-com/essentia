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
Future<List<UuidV7>> _mint(List<UuidV7> shared) async {
  final own = <UuidV7>[];
  for (var index = 0; index < _perTask; index++) {
    final minted = UuidV7.random();
    own.add(minted);
    shared.add(minted);
    if (index % _burst == 0) {
      await _pause();
    }
  }
  return own;
}

/// Whether every identifier in [minted] sorts strictly after the one before.
bool _strictlyAscending(List<UuidV7> minted) {
  for (var index = 1; index < minted.length; index++) {
    if (minted[index].compareTo(minted[index - 1]) <= 0) {
      return false;
    }
  }
  return true;
}

/// Tests minting time-ordered identifiers from many interleaved tasks.
void main() {
  test('minting from several tasks at once produces no collisions', () async {
    final shared = <UuidV7>[];

    final List<List<UuidV7>> minted = await Future.wait(<Future<List<UuidV7>>>[
      for (var task = 0; task < _tasks; task++) _mint(shared),
    ]);

    final all = <UuidV7>{for (final List<UuidV7> batch in minted) ...batch};
    expect(all, hasLength(_tasks * _perTask));
    expect(shared, hasLength(all.length));
    expect(all.containsAll(shared), isTrue);
  });

  test('interleaved tasks still mint in one global order', () async {
    final shared = <UuidV7>[];

    final List<List<UuidV7>> minted = await Future.wait(<Future<List<UuidV7>>>[
      for (var task = 0; task < _tasks; task++) _mint(shared),
    ]);

    expect(_strictlyAscending(shared), isTrue);
    for (final batch in minted) {
      expect(_strictlyAscending(batch), isTrue);
    }
  });

  test('a tight loop of many mints is unique and ascending', () {
    final minted = List<UuidV7>.generate(
      _tasks * _perTask,
      (_) => UuidV7.random(),
    );

    expect(minted.toSet(), hasLength(_tasks * _perTask));
    expect(_strictlyAscending(minted), isTrue);
  });
}
