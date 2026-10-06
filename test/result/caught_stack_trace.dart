/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Runs [block] and captures the stack trace of what it throws.
///
/// Returns the stack trace [block] threw with, or [StackTrace.empty] when
/// it returned normally.
StackTrace caughtStackTrace(void Function() block) {
  try {
    block();
    return StackTrace.empty;
  } on Object catch (_, stackTrace) {
    return stackTrace;
  }
}
