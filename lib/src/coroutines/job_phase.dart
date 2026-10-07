/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// The state of a job, as `toString` renders it.
@internal
enum JobPhase {
  /// Not started yet.
  fresh,

  /// Running.
  active,

  /// Done itself, waiting for its children.
  completing,

  /// Cancelled, waiting for its body and its children.
  cancelling,

  /// Finally cancelled or failed.
  cancelled,

  /// Finally completed.
  completed,
}
