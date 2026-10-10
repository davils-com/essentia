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

/// Reads the components of an iCalendar [text], usually one `VCALENDAR`,
/// unfolding its lines and keeping every property as written.
///
/// Every line it cannot read, every `END` without its `BEGIN` and every
/// component left open is added to [problems] as `line N: what`, and the
/// rest is read on.
List<IcsComponent> readIcs(String text, List<String> problems) {
  final roots = <IcsComponent>[];
  final stack = <(String, List<IcsProperty>, List<IcsComponent>)>[];
  final List<String> lines = unfoldIcs(text);
  for (var index = 0; index < lines.length; index += 1) {
    final IcsProperty? property = parseIcsContentLine(lines[index]);
    if (property == null) {
      problems.add('line ${index + 1}: not a content line');
      continue;
    }
    if (property.name == 'BEGIN') {
      stack.add((
        property.value.toUpperCase(),
        <IcsProperty>[],
        <IcsComponent>[],
      ));
      continue;
    }
    if (property.name == 'END') {
      if (stack.isEmpty || stack.last.$1 != property.value.toUpperCase()) {
        problems.add('line ${index + 1}: END:${property.value} closes nothing');
        continue;
      }
      _close(stack, roots);
      continue;
    }
    if (stack.isEmpty) {
      problems.add('line ${index + 1}: ${property.name} outside a component');
      continue;
    }
    stack.last.$2.add(property);
  }
  while (stack.isNotEmpty) {
    problems.add('end of text: ${stack.last.$1} is not closed');
    _close(stack, roots);
  }
  return roots;
}

/// Closes the innermost open component of [stack] into its parent, or
/// into [roots].
void _close(
  List<(String, List<IcsProperty>, List<IcsComponent>)> stack,
  List<IcsComponent> roots,
) {
  final (String name, List<IcsProperty> properties, List<IcsComponent> nested) =
      stack.removeLast();
  final component = IcsComponent(
    name,
    properties: properties,
    components: nested,
  );
  if (stack.isEmpty) {
    roots.add(component);
    return;
  }
  stack.last.$3.add(component);
}

/// Reads one unfolded content line: `NAME;PARAM=a,"b;c":value`.
///
/// Returns the property, or `null` for a line that is none.
IcsProperty? parseIcsContentLine(String line) {
  final RegExpMatch? head = RegExp('^([A-Za-z0-9-]+)').firstMatch(line);
  if (head == null) {
    return null;
  }
  final String name = head.group(1)!;
  int index = name.length;
  final parameters = <String, List<String>>{};
  while (index < line.length && line[index] == ';') {
    final int equals = line.indexOf('=', index);
    if (equals < 0) {
      return null;
    }
    final String parameter = line.substring(index + 1, equals);
    if (!RegExp(r'^[A-Za-z0-9-]+$').hasMatch(parameter)) {
      return null;
    }
    index = equals + 1;
    final values = <String>[];
    while (true) {
      if (index < line.length && line[index] == '"') {
        final int close = line.indexOf('"', index + 1);
        if (close < 0) {
          return null;
        }
        values.add(line.substring(index + 1, close));
        index = close + 1;
        if (index >= line.length || !',;:'.contains(line[index])) {
          return null;
        }
      }
      final int end = _nextDelimiter(line, index);
      if (end > index) {
        values.add(line.substring(index, end));
      }
      index = end;
      if (index < line.length && line[index] == ',') {
        index += 1;
        continue;
      }
      break;
    }
    parameters
        .putIfAbsent(parameter.toUpperCase(), () => <String>[])
        .addAll(values);
  }
  if (index >= line.length || line[index] != ':') {
    return null;
  }
  return IcsProperty(name, line.substring(index + 1), parameters: parameters);
}

/// The index of the next `,`, `;` or `:` of [line] from [start], or its
/// length.
int _nextDelimiter(String line, int start) {
  for (var index = start; index < line.length; index += 1) {
    final String character = line[index];
    if (character == ',' || character == ';' || character == ':') {
      return index;
    }
  }
  return line.length;
}
