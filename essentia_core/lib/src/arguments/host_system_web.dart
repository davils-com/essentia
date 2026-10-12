/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/arguments/conversion_exception.dart';
import 'package:meta/meta.dart';

/// The environment of a host that has none, such as a browser.
///
/// Returns an empty map, so every parameter falls back to the command line,
/// its value sources and its default.
@internal
Map<String, String> hostEnvironment() => const <String, String>{};

/// Checks what [path] points at on a host without a file system.
///
/// A path that has to satisfy nothing passes. A requirement cannot be
/// checked here, and a check that cannot be made is refused rather than
/// passed, so a path that must exist never silently does.
///
/// Throws a [ConversionException] if any requirement was declared.
@internal
void checkPath(
  String path, {
  required bool mustExist,
  required bool mustBeReadable,
  required bool mustBeDirectory,
  required bool mustBeRegularFile,
}) {
  final bool checked =
      mustExist || mustBeReadable || mustBeDirectory || mustBeRegularFile;
  if (checked) {
    throw const ConversionException(
      'cannot be checked on a platform without a file system',
    );
  }
}
