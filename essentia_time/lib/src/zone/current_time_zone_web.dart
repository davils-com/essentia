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
