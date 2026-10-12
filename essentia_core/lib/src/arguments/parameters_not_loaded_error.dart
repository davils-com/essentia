/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Thrown when a schema is read before it was loaded.
///
/// This is a defect in the program's startup order, not a problem with what
/// the user passed, and it is deliberately an error rather than a
/// `ParameterException` so that the two can never be confused for one
/// another: an unloaded schema and a genuinely missing value must not look
/// alike, or startup bugs look like user error.
final class ParametersNotLoadedError extends StateError {
  /// Creates the error for [subject], which was read too early.
  @internal
  ParametersNotLoadedError(String subject)
    : super('$subject was accessed before load() was called on its schema');
}
