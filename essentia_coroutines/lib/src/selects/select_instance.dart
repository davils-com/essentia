/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:meta/meta.dart';

/// A running `select` as one of its clauses sees it.
///
/// A clause registers with it: it selects at once when it is ready, or
/// waits and selects later through [trySelect]. Exactly one clause of a
/// select wins; every other one is told so by [trySelect] returning
/// `false`, and the handles it registered are disposed.
@internal
abstract interface class SelectInstance {
  /// The select this clause belongs to.
  ///
  /// A channel never pairs a sender and a receiver of the same select.
  Object get owner;

  /// Selects this clause with [result], unless another clause won or the
  /// select ended.
  ///
  /// [onCancellation] runs when the caller of the select is cancelled after
  /// this call and before it takes [result], so an element handed over is
  /// never lost.
  ///
  /// Returns whether this clause won.
  bool trySelect(Object? result, {void Function()? onCancellation});

  /// Disposes [handle] once the select is over, at once when it is over
  /// already.
  void disposeOnCompletion(Disposable handle);
}
