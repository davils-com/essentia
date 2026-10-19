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

/// How many values a parameter resolves to, and what happens without one.
@internal
enum Cardinality {
  /// At most one value; absent is `null`.
  optional,

  /// Exactly one value; absent is a violation.
  required,

  /// At most one value; absent is the declared default.
  defaulted,

  /// Any number of values, collected into a list.
  multiple,
}
