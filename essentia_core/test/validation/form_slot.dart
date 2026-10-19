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

/// One slot of the workspace form validated by the standalone validation
/// tests.
@immutable
final class FormSlot {
  /// Creates the slot [name] holding [size] units.
  const FormSlot(this.name, this.size);

  /// The name of the slot.
  final String name;

  /// How many units the slot holds.
  final int size;
}
