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

import 'package:essentia_core/src/arguments/host_system_io.dart';
import 'package:essentia_core/src/arguments/parameter_builder.dart';

/// The conversion of a parameter to a `dart:io` [File], available on the
/// platforms that have one.
extension FileParameterConverters on ParameterBuilder<String> {
  /// Converts the value to a [File], optionally checking what it points at.
  ///
  /// The checks are the ones of `path`, run as part of conversion, so a
  /// file that does not satisfy them is reported alongside every other
  /// parameter problem, and a declared default is checked as well.
  ///
  /// Returns a builder producing files.
  ParameterBuilder<File> file({
    bool mustExist = false,
    bool mustBeReadable = false,
    bool mustBeDirectory = false,
    bool mustBeRegularFile = false,
  }) => ParameterBuilder<File>(
    draft.retyped(
      'file',
      File.new,
      (value) => checkPath(
        (value! as File).path,
        mustExist: mustExist,
        mustBeReadable: mustBeReadable,
        mustBeDirectory: mustBeDirectory,
        mustBeRegularFile: mustBeRegularFile,
      ),
    ),
  );
}
