/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// How much weight a violation carries.
enum Severity {
  /// Something worth saying that does not stop anything.
  ///
  /// A report containing only warnings is still valid, and the object it
  /// describes is still built. Warnings are for what is legal but probably
  /// not meant: a deprecated parameter that is still honoured, a setting
  /// that will be expensive in production.
  warning,

  /// Something that makes the result unusable.
  ///
  /// A single error invalidates the whole report; the object is not built
  /// and nothing partially configured escapes.
  error,
}
