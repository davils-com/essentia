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
