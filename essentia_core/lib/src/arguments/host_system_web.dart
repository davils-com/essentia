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
