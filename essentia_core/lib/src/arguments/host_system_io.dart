/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:io';

import 'package:essentia_core/src/arguments/conversion_exception.dart';
import 'package:meta/meta.dart';

/// The environment of this process.
///
/// Returns the variables by name.
@internal
Map<String, String> hostEnvironment() => Platform.environment;

/// Checks what [path] points at.
///
/// [mustBeReadable], [mustBeDirectory] and [mustBeRegularFile] each imply
/// [mustExist].
///
/// Throws a [ConversionException] naming the first requirement it misses.
@internal
void checkPath(
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
