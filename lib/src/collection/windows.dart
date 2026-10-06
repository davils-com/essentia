/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:collection';
import 'dart:math';

import 'package:essentia/src/collection/window_shape.dart';
import 'package:meta/meta.dart';

/// Checks that the size and the step of [shape] are positive.
///
/// Returns [shape].
///
/// Throws a [RangeError] if either is smaller than one.
@internal
WindowShape checkedWindowShape(WindowShape shape) {
  checkPositive(shape.size, 'size');
  checkPositive(shape.step, 'step');
  return shape;
}

/// Checks that [value], the argument [name], is at least one.
///
/// Returns [value].
///
/// Throws a [RangeError] if it is smaller.
@internal
int checkPositive(int value, String name) {
  if (value < 1) {
    throw RangeError.range(value, 1, null, name);
  }
  return value;
}

/// Lazily cuts [source] into windows of [shape].
///
/// Returns every window as an unmodifiable list, in order.
@internal
Iterable<List<T>> windowsOf<T>(Iterable<T> source, WindowShape shape) sync* {
  final window = ListQueue<T>(shape.size);
  var skipped = 0;
  for (final element in source) {
    if (skipped > 0) {
      skipped--;
      continue;
    }
    window.add(element);
    if (window.length == shape.size) {
      yield List<T>.unmodifiable(window);
      skipped = _advance(window, shape.step);
    }
  }
  if (shape.remainder.keepsPartialWindows) {
    yield* _partialWindows(window, shape.step);
  }
}

/// The partial windows left in [window] once the source ran out, each
/// [step] elements shorter than the one before.
///
/// Returns them in order.
Iterable<List<T>> _partialWindows<T>(ListQueue<T> window, int step) sync* {
  while (window.isNotEmpty) {
    yield List<T>.unmodifiable(window);
    _advance(window, step);
  }
}

/// Moves [window] on by [step] elements, dropping what it holds first.
///
/// Returns how many elements of the source still have to be skipped when
/// the step is larger than the window.
int _advance<T>(ListQueue<T> window, int step) {
  final int dropped = min(step, window.length);
  for (var index = 0; index < dropped; index++) {
    window.removeFirst();
  }
  return step - dropped;
}
