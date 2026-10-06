/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:io';

import 'package:essentia/src/arguments/application_mode.dart';
import 'package:essentia/src/arguments/boolean_parser.dart';
import 'package:essentia/src/arguments/conversion_exception.dart';
import 'package:essentia/src/arguments/converter.dart';
import 'package:essentia/src/arguments/duration_parser.dart';
import 'package:essentia/src/arguments/parameter_builder.dart';

/// The conversions a parameter declared as text can be given.
///
/// A conversion fixes the type of the parameter, so it comes before any
/// `validate`: a rule written against the text cannot apply to the
/// converted value.
///
/// ```dart
/// late final Parameter<int> port =
///     parameter(['--port']).integer().required();
/// late final Parameter<Duration?> timeout =
///     parameter(['--timeout']).duration();
/// ```
extension ParameterConverters on ParameterBuilder<String> {
  /// Converts the value with [converter], reporting it as [typeName] in the
  /// usage listing.
  ///
  /// This is the escape hatch for types Essentia does not know about. The
  /// converter throws a [ConversionException] for input it rejects.
  ///
  /// Returns a builder producing the converted type.
  ///
  /// Throws a [StateError] if validation was already declared.
  ParameterBuilder<R> convert<R>(String typeName, Converter<R> converter) =>
      ParameterBuilder<R>(schema, draft.retyped(typeName, converter));

  /// Converts the value to an [int].
  ///
  /// Returns a builder producing integers.
  ParameterBuilder<int> integer() => convert<int>(
    'int',
    (raw) =>
        int.tryParse(raw) ??
        (throw const ConversionException('is not a valid integer')),
  );

  /// Converts the value to a [double].
  ///
  /// Returns a builder producing decimal numbers.
  ParameterBuilder<double> decimal() => convert<double>(
    'double',
    (raw) =>
        double.tryParse(raw) ??
        (throw const ConversionException('is not a valid decimal number')),
  );

  /// Converts the value to a [bool].
  ///
  /// Accepts `true`, `yes`, `on` and `1` as true and `false`, `no`,
  /// `off` and `0` as false, in any capitalisation. Anything else is
  /// rejected rather than silently read as false.
  ///
  /// Returns a builder producing booleans.
  ParameterBuilder<bool> boolean() => convert<bool>('boolean', parseBoolean);

  /// Restricts the value to one of [allowed], leaving it a [String].
  ///
  /// Returns a builder producing one of the allowed values.
  ParameterBuilder<String> choice(List<String> allowed) {
    final accepted = List<String>.unmodifiable(allowed);
    return convert<String>('choice', (raw) {
      if (!accepted.contains(raw)) {
        throw ConversionException('is not one of ${accepted.join(', ')}');
      }
      return raw;
    });
  }

  /// Converts the value to the constant of [values] whose name matches,
  /// ignoring capitalisation.
  ///
  /// A value that matches nothing is reported together with the constants
  /// that would have worked. The usage listing shows the names.
  ///
  /// Returns a builder producing enum constants.
  ParameterBuilder<E> enumeration<E extends Enum>(List<E> values) {
    final String names = values.map((value) => value.name).join('|');
    return convert<E>(names, (raw) {
      final String wanted = raw.toLowerCase();
      for (final value in values) {
        if (value.name.toLowerCase() == wanted) {
          return value;
        }
      }
      throw ConversionException(
        'is not one of ${values.map((value) => value.name).join(', ')}',
      );
    });
  }

  /// Keeps the value as a path, optionally checking what it points at.
  ///
  /// The checks run as part of conversion, so a path that does not satisfy
  /// them is reported alongside every other parameter problem instead of
  /// failing later when the program first opens it. [mustBeReadable],
  /// [mustBeDirectory] and [mustBeRegularFile] each imply [mustExist].
  ///
  /// Returns a builder producing paths.
  ParameterBuilder<String> path({
    bool mustExist = false,
    bool mustBeReadable = false,
    bool mustBeDirectory = false,
    bool mustBeRegularFile = false,
  }) => convert<String>('path', (raw) {
    _checkPath(
      raw,
      mustExist: mustExist,
      mustBeReadable: mustBeReadable,
      mustBeDirectory: mustBeDirectory,
      mustBeRegularFile: mustBeRegularFile,
    );
    return raw;
  });

  /// Converts the value to a [File], optionally checking what it points at.
  ///
  /// The checks are the ones of [path].
  ///
  /// Returns a builder producing files.
  ParameterBuilder<File> file({
    bool mustExist = false,
    bool mustBeReadable = false,
    bool mustBeDirectory = false,
    bool mustBeRegularFile = false,
  }) => convert<File>('file', (raw) {
    _checkPath(
      raw,
      mustExist: mustExist,
      mustBeReadable: mustBeReadable,
      mustBeDirectory: mustBeDirectory,
      mustBeRegularFile: mustBeRegularFile,
    );
    return File(raw);
  });

  /// Converts the value to a [Uri].
  ///
  /// Returns a builder producing URIs.
  ParameterBuilder<Uri> uri() => convert<Uri>('uri', (raw) {
    try {
      return Uri.parse(raw);
    } on FormatException catch (failure) {
      throw ConversionException(
        'is not a valid URI: ${failure.message}',
        failure,
      );
    }
  });

  /// Converts the value to a [Duration].
  ///
  /// Accepts both the readable form (`30s`, `1h 30m`, `250ms`) and
  /// ISO-8601 (`PT30S`).
  ///
  /// Returns a builder producing durations.
  ParameterBuilder<Duration> duration() => convert<Duration>(
    'duration',
    (raw) =>
        parseDuration(raw) ??
        (throw const ConversionException(
          'is not a valid duration, expected something like 30s, 5m or PT1H',
        )),
  );

  /// Converts the value to an [ApplicationMode].
  ///
  /// Returns a builder producing application modes.
  ParameterBuilder<ApplicationMode> applicationMode() =>
      convert<ApplicationMode>(
        'mode',
        (raw) =>
            ApplicationMode.tryByValue(raw) ??
            (throw ConversionException(
              'is not an application mode, expected one of '
              '${ApplicationMode.values.map((mode) => mode.value).join(', ')}',
            )),
      );
}

/// Checks what [path] points at.
///
/// Throws a [ConversionException] naming the first requirement it misses.
void _checkPath(
  String path, {
  required bool mustExist,
  required bool mustBeReadable,
  required bool mustBeDirectory,
  required bool mustBeRegularFile,
}) {
  final FileSystemEntityType type = FileSystemEntity.typeSync(path);
  final bool needsToExist =
      mustExist || mustBeReadable || mustBeDirectory || mustBeRegularFile;
  if (needsToExist && type == FileSystemEntityType.notFound) {
    throw const ConversionException('does not exist');
  }
  if (mustBeReadable && !_isReadable(path, type)) {
    throw const ConversionException('is not readable');
  }
  if (mustBeDirectory && type != FileSystemEntityType.directory) {
    throw const ConversionException('is not a directory');
  }
  if (mustBeRegularFile && type != FileSystemEntityType.file) {
    throw const ConversionException('is not a regular file');
  }
}

/// Whether [path], of [type], can be read, found out by reading it.
bool _isReadable(String path, FileSystemEntityType type) {
  try {
    if (type == FileSystemEntityType.directory) {
      Directory(path).listSync();
      return true;
    }
    File(path).openSync().closeSync();
    return true;
  } on FileSystemException {
    return false;
  }
}
