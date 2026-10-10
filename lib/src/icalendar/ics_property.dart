/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// One content line of an iCalendar file: a [name], its [parameters] and
/// its raw [value], exactly as written, escapes included.
///
/// `DTSTART;TZID=Europe/Berlin:20261009T090000` is the property `DTSTART`
/// with the parameter `TZID` and the value `20261009T090000`.
@immutable
final class IcsProperty {
  /// The property [name] of [value] with [parameters].
  ///
  /// The name and the parameter names are kept in upper case, as RFC 5545
  /// compares them without case.
  IcsProperty(
    String name,
    this.value, {
    Map<String, List<String>> parameters = const <String, List<String>>{},
  }) : name = name.toUpperCase(),
       parameters = Map<String, List<String>>.unmodifiable(
         <String, List<String>>{
           for (final MapEntry<String, List<String>> entry
               in parameters.entries)
             entry.key.toUpperCase(): List<String>.unmodifiable(entry.value),
         },
       );

  /// The name, in upper case.
  final String name;

  /// The value as written, escapes included.
  final String value;

  /// The parameters by name, each with its values.
  final Map<String, List<String>> parameters;

  /// The first value of the parameter [name], or `null`.
  String? parameter(String name) {
    final List<String>? values = parameters[name.toUpperCase()];
    return values == null || values.isEmpty ? null : values.first;
  }

  /// Whether [other] is the same line.
  @override
  bool operator ==(Object other) =>
      other is IcsProperty &&
      other.name == name &&
      other.value == value &&
      other.parameters.length == parameters.length &&
      parameters.entries.every(
        (entry) =>
            other.parameters[entry.key]?.join('\u0000') ==
            entry.value.join('\u0000'),
      );

  /// A hash of the line.
  @override
  int get hashCode => Object.hash(
    name,
    value,
    Object.hashAllUnordered(
      parameters.entries.map(
        (entry) => Object.hash(entry.key, Object.hashAll(entry.value)),
      ),
    ),
  );

  /// Describes the line as it would be written, unfolded.
  @override
  String toString() {
    final buffer = StringBuffer(name);
    for (final MapEntry<String, List<String>> entry in parameters.entries) {
      buffer.write(';${entry.key}=${entry.value.map(_quoted).join(',')}');
    }
    buffer.write(':$value');
    return buffer.toString();
  }

  /// [value] in quotes when it holds a character that needs them.
  static String _quoted(String value) =>
      value.contains(RegExp('[:;,]')) ? '"$value"' : value;
}
