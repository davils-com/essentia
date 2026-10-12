/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/job/completion_handler.dart';
import 'package:meta/meta.dart';

/// A completion handler registered with a job.
@internal
final class JobHandler {
  /// Creates the registration of [handler], run when the job starts to be
  /// cancelled if [onCancelling].
  JobHandler(this.handler, {required this.onCancelling});

  /// What runs.
  final CompletionHandler handler;

  /// Whether the handler runs when the job starts to be cancelled instead
  /// of when it completes.
  final bool onCancelling;

  /// Whether the handler ran or was removed.
  var done = false;
}
