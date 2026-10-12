/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
