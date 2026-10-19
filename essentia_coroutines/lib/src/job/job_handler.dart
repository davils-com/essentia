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
