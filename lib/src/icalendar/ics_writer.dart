/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/icalendar/ics_component.dart';
import 'package:essentia/src/icalendar/ics_property.dart';
import 'package:essentia/src/icalendar/ics_text.dart';

/// Writes [component] as iCalendar text: `BEGIN` and `END` around its
/// properties and nested components, every line folded and ended with
/// CRLF, as RFC 5545 asks.
String writeIcs(IcsComponent component) {
  final buffer = StringBuffer();
  _write(component, buffer);
  return buffer.toString();
}

/// Writes [component] into [buffer].
void _write(IcsComponent component, StringBuffer buffer) {
  buffer.write('BEGIN:${component.name}\r\n');
  for (final IcsProperty property in component.properties) {
    buffer.write('${foldIcsLine(property.toString())}\r\n');
  }
  for (final IcsComponent nested in component.components) {
    _write(nested, buffer);
  }
  buffer.write('END:${component.name}\r\n');
}
