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

/// Covers building and rendering a violation path.
void main() {
  test('the root path renders as nothing', () {
    expect(ViolationPath.root.toString(), isEmpty);
    expect(ViolationPath.root.isRoot, isTrue);
  });

  test('a single name renders on its own', () {
    expect(ViolationPath.of('sinks').toString(), 'sinks');
    expect(ViolationPath.of('sinks').isRoot, isFalse);
  });

  test('a name that is not an identifier is still a valid path', () {
    expect(ViolationPath.of('--port').toString(), '--port');
    expect(ViolationPath.of('APP_DATA_DIR').toString(), 'APP_DATA_DIR');
  });

  test('names are joined with dots and indices attach without one', () {
    final ViolationPath path = ViolationPath.of('sinks')
        .index(2)
        .name('async')
        .name('queueSize');

    expect(path.toString(), 'sinks[2].async.queueSize');
  });

  test('a map key renders in quoted brackets', () {
    final ViolationPath path = ViolationPath.of('loggers')
        .key('com.davils')
        .name('level');

    expect(path.toString(), 'loggers["com.davils"].level');
  });

  test('an index or a key at the root renders without a leading dot', () {
    expect(ViolationPath.root.index(3).toString(), '[3]');
    expect(ViolationPath.root.key('port').toString(), '["port"]');
  });

  test('adding two paths concatenates their segments', () {
    final ViolationPath outer = ViolationPath.of('sinks').index(0);
    final ViolationPath inner = ViolationPath.of('async').name('queueSize');

    expect((outer + inner).toString(), 'sinks[0].async.queueSize');
  });

  test('adding the root path changes nothing', () {
    final path = ViolationPath.of('sinks');

    expect((path + ViolationPath.root).toString(), 'sinks');
    expect((ViolationPath.root + path).toString(), 'sinks');
    expect(path + ViolationPath.root, path);
  });

  test('paths built the same way are equal', () {
    expect(
      ViolationPath.of('sinks').index(1),
      ViolationPath.of('sinks').index(1),
    );
    expect(
      ViolationPath.of('sinks').index(1),
      isNot(ViolationPath.of('sinks').index(2)),
    );
  });

  test('a single name containing a dot is not the same path as two names', () {
    final oneSegment = ViolationPath.of('a.b');
    final ViolationPath twoSegments = ViolationPath.of('a').name('b');

    expect(oneSegment.toString(), twoSegments.toString());
    expect(oneSegment, isNot(twoSegments));
  });

  test('a key is not the same path as a property of the same text', () {
    expect(ViolationPath.root.key('port'), isNot(ViolationPath.of('port')));
  });

  test('equal paths agree on their hash', () {
    final ViolationPath left = ViolationPath.of('sinks')
        .index(2)
        .name('queueSize');
    final ViolationPath right = ViolationPath.of('sinks')
        .index(2)
        .name('queueSize');

    expect(left, right);
    expect(left.hashCode, right.hashCode);
  });

  test('appending never changes the path it came from', () {
    final base = ViolationPath.of('sinks');

    final ViolationPath deeper = base.index(1).name('queueSize');

    expect(base.toString(), 'sinks');
    expect(deeper.toString(), 'sinks[1].queueSize');
  });

  test('the segments of a path cannot be changed from outside', () {
    final ViolationPath path = ViolationPath.of('sinks').index(1);

    expect(
      () => path.segments.add(const NameSegment('extra')),
      throwsUnsupportedError,
    );
  });
}
