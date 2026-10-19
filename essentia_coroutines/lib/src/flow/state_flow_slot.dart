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

import 'package:meta/meta.dart';

/// The place of one listener of a state flow.
@internal
final class StateFlowSlot {
  /// Creates the slot of a new listener, which has the current value
  /// pending.
  StateFlowSlot();

  /// Whether the value may have changed since the listener looked last.
  var pending = true;

  /// Queues the pump of the listener, `null` until it is hooked up.
  void Function()? wake;
}
