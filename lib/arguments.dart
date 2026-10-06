/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Program parameters: declare what a program accepts, load it once at
/// startup, then read typed, immutable values.
///
/// Needs `dart:io` for the process environment and for the file system
/// checks of path parameters, which is why it is not part of
/// `package:essentia/essentia.dart`.
library;

export 'src/arguments/application_mode.dart';
export 'src/arguments/conversion_exception.dart';
export 'src/arguments/converter.dart';
export 'src/arguments/defaulted_parameter_builder.dart';
export 'src/arguments/flag_builder.dart';
export 'src/arguments/multiple_parameter_builder.dart';
export 'src/arguments/parameter.dart';
export 'src/arguments/parameter_builder.dart';
export 'src/arguments/parameter_converters.dart';
export 'src/arguments/parameter_exception.dart';
export 'src/arguments/parameter_info.dart';
export 'src/arguments/parameter_violation.dart';
export 'src/arguments/parameter_violation_codes.dart';
export 'src/arguments/parameters.dart';
export 'src/arguments/parameters_not_loaded_error.dart';
export 'src/arguments/required_parameter_builder.dart';
export 'src/arguments/unknown_argument_policy.dart';
export 'src/arguments/value_origin.dart';
export 'src/arguments/value_source.dart';
