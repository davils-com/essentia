/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:math';

import 'package:essentia_core/src/arguments/masking.dart';
import 'package:essentia_core/src/arguments/parameter_info.dart';
import 'package:essentia_core/src/arguments/parameter_snapshot.dart';
import 'package:essentia_core/src/arguments/parameter_spec.dart';
import 'package:essentia_core/src/arguments/value_origin.dart';
import 'package:essentia_core/src/validation/column.dart';
import 'package:meta/meta.dart';

/// The widest the name column grows before longer names push the rest to
/// the right.
const _columnLimit = 34;

/// The gap between the name column and the rest.
const _columnGap = 2;

/// The indentation of every line.
const _indent = '  ';

/// Renders the listing of the parameters [specs] declares.
///
/// Returns the listing, without a trailing newline.
@internal
String renderUsage(List<ParameterSpec> specs) {
  if (specs.isEmpty) {
    return 'This program takes no parameters.';
  }
  final entries = <(String, String)>[
    for (final spec in specs)
      (_renderSignature(spec.info), _renderAnnotations(spec.info)),
  ];
  final int width = _columnWidth(entries.map((entry) => entry.$1));
  final String lines = entries
      .map(
        (entry) => '$_indent${column(entry.$1, width)}${entry.$2}'.trimRight(),
      )
      .join('\n');
  return 'Supported parameters:\n$lines';
}

/// Renders the values of [snapshot] together with where each came from.
///
/// Returns the rendered values, without a trailing newline.
@internal
String renderValues(List<ParameterSpec> specs, ParameterSnapshot snapshot) {
  if (specs.isEmpty) {
    return 'This program takes no parameters.';
  }
  final entries = <(String, String)>[
    for (final spec in specs)
      (spec.info.primaryName, _renderValue(spec, snapshot)),
  ];
  final int width = _columnWidth(entries.map((entry) => entry.$1));
  final String lines = entries
      .map((entry) => '$_indent${column(entry.$1, width)}${entry.$2}')
      .join('\n');
  return 'Parameters:\n$lines';
}

/// Renders the names of [info] and, unless it is a flag, its type.
///
/// Returns `--port, -p <int>`.
String _renderSignature(ParameterInfo info) {
  final String names = info.names.join(', ');
  if (info.isFlag) {
    return names;
  }
  return '$names <${info.typeName}>';
}

/// Renders what the listing says about [info] beside its signature.
///
/// Returns the description and the notes, separated by two spaces.
String _renderAnnotations(ParameterInfo info) {
  final String? description = info.description;
  final String? defaultDisplay = info.defaultDisplay;
  final String? variable = info.environmentVariable;
  return <String>[
    ?description,
    if (info.isRequired) 'required',
    if (info.acceptsMultiple) 'repeatable',
    if (defaultDisplay != null) 'default: $defaultDisplay',
    if (variable != null) 'env: $variable',
    if (info.deprecation != null) 'deprecated',
  ].join('  ');
}

/// Renders the value of [spec], masked when it is sensitive, and where it
/// came from.
///
/// Returns `8080 (from APP_PORT)`.
String _renderValue(ParameterSpec spec, ParameterSnapshot snapshot) {
  final Object? value = snapshot.valueAt(spec.ordinal);
  final String rendered = spec.info.isSensitive ? maskValue(value) : '$value';
  final ValueOrigin? origin = snapshot.originAt(spec.ordinal);
  if (origin == null) {
    return rendered;
  }
  return '$rendered ${_originSuffix(origin)}';
}

/// Renders where a value came from.
///
/// Returns the origin in parentheses.
String _originSuffix(ValueOrigin origin) => switch (origin) {
  CommandLineOrigin() => '(from the command line)',
  DefaultOrigin() => '(default)',
  EnvironmentOrigin(:final variable) => '(from $variable)',
  ExternalOrigin(:final sourceName) => '(from $sourceName)',
};

/// The width of the name column for [labels].
///
/// Returns the longest label, capped at the limit, plus the gap.
int _columnWidth(Iterable<String> labels) {
  final int longest = labels.map((label) => label.length).reduce(max);
  return min(longest, _columnLimit) + _columnGap;
}
