/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/coroutines/abstract_coroutine.dart';
import 'package:essentia/src/coroutines/exception_handling.dart';
import 'package:meta/meta.dart';

/// The coroutine `launch` starts: its failure, unless the parent takes it
/// over, is reported to the `CoroutineExceptionHandler` of its context.
@internal
final class StandaloneCoroutine extends AbstractCoroutine<void> {
  /// Creates the coroutine with [parentContext], [active] at once or
  /// started lazily.
  StandaloneCoroutine(super.parentContext, {required super.active});

  /// Names the kind of coroutine.
  @override
  String get kind => 'StandaloneCoroutine';

  /// Reports [error] through the context.
  ///
  /// Returns `true`.
  @override
  bool handleJobException(Object error, StackTrace stackTrace) {
    handleCoroutineException(coroutineContext, error, stackTrace, zone: zone);
    return true;
  }
}
