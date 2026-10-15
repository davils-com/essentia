/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/essentia_coroutines.dart';

/// The coroutine that writes or reads one side of a byte channel, Ktor's
/// `ChannelJob`.
abstract interface class ChannelJob {
  /// The job of the coroutine, to wait for or cancel it.
  Job get job;
}
