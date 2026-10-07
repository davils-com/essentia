/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/coroutines/coroutine_context.dart';
import 'package:essentia/src/coroutines/coroutine_scope.dart';
import 'package:meta/meta.dart';

/// A dispatcher that runs a whole body somewhere else, such as on another
/// isolate, instead of starting it on the event loop of this one.
@internal
abstract interface class RemoteDispatcher {
  /// Whether bodies really run somewhere else; when not, they start as
  /// on any other dispatcher.
  bool get remote;

  /// Runs [block] with the sendable elements of [context] and waits for its
  /// result; cancelling the job of [context] cancels it.
  ///
  /// Returns what [block] returns.
  Future<T> execute<T>(
    CoroutineContext context,
    FutureOr<T> Function(CoroutineScope it) block,
  );
}
