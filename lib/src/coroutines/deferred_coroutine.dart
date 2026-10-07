/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/coroutines/abstract_coroutine.dart';
import 'package:essentia/src/coroutines/deferred_mixin.dart';
import 'package:meta/meta.dart';

/// The coroutine `async` starts: its failure stays in it, for whoever
/// awaits it.
@internal
final class DeferredCoroutine<T> extends AbstractCoroutine<T>
    with DeferredMixin<T> {
  /// Creates the coroutine with [parentContext], [active] at once or
  /// started lazily.
  DeferredCoroutine(super.parentContext, {required super.active});

  /// Names the kind of coroutine.
  @override
  String get kind => 'DeferredCoroutine';
}
