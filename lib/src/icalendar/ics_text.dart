/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:convert';

/// The lines of an iCalendar text with folded lines joined: a line break
/// followed by a space or a tab continues the line before. Breaks may be
/// CRLF, LF or CR.
List<String> unfoldIcs(String text) {
  final List<String> raw = text.split(RegExp(r'\r\n|\n|\r'));
  final lines = <String>[];
  for (final line in raw) {
    if ((line.startsWith(' ') || line.startsWith('\t')) && lines.isNotEmpty) {
      lines.last = '${lines.last}${line.substring(1)}';
      continue;
    }
    lines.add(line);
  }
  return <String>[
    for (final line in lines)
      if (line.isNotEmpty) line,
  ];
}

/// [line] folded as RFC 5545 asks: no line longer than 75 octets of
/// UTF-8, continuations starting with a space, never inside a character.
String foldIcsLine(String line) {
  final buffer = StringBuffer();
  var octets = 0;
  var limit = 75;
  for (final int rune in line.runes) {
    final character = String.fromCharCode(rune);
    final int size = utf8.encode(character).length;
    if (octets + size > limit) {
      buffer.write('\r\n ');
      octets = 0;
      limit = 74;
    }
    buffer.write(character);
    octets += size;
  }
  return buffer.toString();
}

/// [text] as an iCalendar text value: backslashes, semicolons, commas and
/// line breaks escaped.
String escapeIcsText(String text) => text
    .replaceAll(r'\', r'\\')
    .replaceAll(';', r'\;')
    .replaceAll(',', r'\,')
    .replaceAll(RegExp(r'\r\n|\n|\r'), r'\n');

/// The text an iCalendar text [value] stands for, its escapes resolved.
String unescapeIcsText(String value) {
  final buffer = StringBuffer();
  for (var index = 0; index < value.length; index += 1) {
    final String character = value[index];
    if (character != r'\' || index + 1 >= value.length) {
      buffer.write(character);
      continue;
    }
    index += 1;
    final String next = value[index];
    buffer.write(next == 'n' || next == 'N' ? '\n' : next);
  }
  return buffer.toString();
}

/// The parts of a list [value], split at commas that are not escaped, each
/// still escaped.
List<String> splitIcsList(String value) {
  final parts = <String>[];
  final current = StringBuffer();
  for (var index = 0; index < value.length; index += 1) {
    final String character = value[index];
    if (character == r'\' && index + 1 < value.length) {
      current
        ..write(character)
        ..write(value[index + 1]);
      index += 1;
      continue;
    }
    if (character == ',') {
      parts.add(current.toString());
      current.clear();
      continue;
    }
    current.write(character);
  }
  parts.add(current.toString());
  return parts;
}
