/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// What a schema does with arguments it does not declare.
enum UnknownArgumentPolicy {
  /// An undeclared argument is a violation, reported with the closest
  /// declared name when there is one.
  ///
  /// This is the default, because the usual cause is a typo, and a program
  /// that silently ignores `--porrt=9090` starts on the wrong port instead
  /// of saying so.
  reject,

  /// An undeclared argument is collected into `Parameters.unknown` and
  /// loading continues.
  ///
  /// Use this when the program forwards arguments it does not own to
  /// something else.
  collect,
}
