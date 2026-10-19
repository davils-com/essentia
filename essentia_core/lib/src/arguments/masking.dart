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

/// What a masked value is rendered as.
@internal
const mask = '****';

/// Renders [value] with its contents masked, keeping only its shape.
///
/// Returns one mask per element of a list, `null` for nothing, and a single
/// mask otherwise.
@internal
String maskValue(Object? value) {
  if (value is List<Object?>) {
    return '[${value.map((_) => mask).join(', ')}]';
  }
  if (value == null) {
    return 'null';
  }
  return mask;
}
