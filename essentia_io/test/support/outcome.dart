/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

/// Runs [body] and hands out what it failed with, so that a coroutine that
/// is meant to fail does not fail the test that started it.
///
/// Returns the failure, or `null` when [body] completed.
Future<Object?> failureOf(FutureOr<void> Function() body) async {
  try {
    await body();
    return null;
  } on Object catch (error) {
    return error;
  }
}
