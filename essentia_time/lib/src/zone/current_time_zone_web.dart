/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:meta/meta.dart';

/// Reads the name of the time zone of the browser from
/// `Intl.DateTimeFormat().resolvedOptions().timeZone`.
///
/// Returns the name, or `null` when the browser does not tell it.
@internal
String? systemTimeZoneId() {
  final JSObject? intl = globalContext.getProperty<JSObject?>('Intl'.toJS);
  if (intl == null) {
    return null;
  }
  final JSFunction format = intl.getProperty<JSFunction>('DateTimeFormat'.toJS);
  final JSObject options = format
      .callAsConstructor<JSObject>()
      .callMethod<JSObject>('resolvedOptions'.toJS);
  final JSString? zone = options.getProperty<JSString?>('timeZone'.toJS);
  return zone?.toDart;
}
