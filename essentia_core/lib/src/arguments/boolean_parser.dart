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

import 'package:essentia_core/src/arguments/conversion_exception.dart';
import 'package:meta/meta.dart';

/// The spellings of true.
const _truthy = <String>{'true', 'yes', 'on', '1'};

/// The spellings of false.
const _falsy = <String>{'false', 'no', 'off', '0'};

/// Reads [raw] as a boolean, in any capitalisation.
///
/// Returns the boolean.
///
/// Throws a [ConversionException] for anything that is neither spelling.
@internal
bool parseBoolean(String raw) {
  final String normalised = raw.toLowerCase();
  if (_truthy.contains(normalised)) {
    return true;
  }
  if (_falsy.contains(normalised)) {
    return false;
  }
  throw const ConversionException(
    'is not a boolean, expected one of true, false, yes, no, on, off, 1, 0',
  );
}
