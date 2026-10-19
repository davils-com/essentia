/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
