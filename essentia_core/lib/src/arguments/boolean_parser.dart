/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
