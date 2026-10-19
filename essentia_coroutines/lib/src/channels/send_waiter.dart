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

import 'dart:collection';

import 'package:meta/meta.dart';

/// A sender waiting until a channel takes its [element].
///
/// The channel resumes it before it moves the element anywhere, so a
/// waiter that cannot take part any more - a select that chose another
/// clause - keeps the element where it is.
@internal
abstract base class SendWaiter<E> extends LinkedListEntry<SendWaiter<E>> {
  /// Creates the waiter of a sender holding [element].
  SendWaiter(this.element);

  /// The element the sender waits to hand over.
  final E element;

  /// The select the waiter belongs to, `null` for a plain send.
  Object? get owner => null;

  /// Tells the sender that the channel took [element].
  ///
  /// Returns `false` when the sender is gone, so the element must stay.
  bool resume();

  /// Tells the sender that the channel was cancelled, with [error].
  ///
  /// Returns whether the sender was still there, so that its element counts
  /// as undelivered.
  bool fail(Object error);
}
