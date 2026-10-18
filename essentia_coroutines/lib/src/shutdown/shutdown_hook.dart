/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_coroutines/src/shutdown/shutdown_signal.dart';

/// Work that has to be done when the host signals the end of the program:
/// flushing logs, stopping a server, closing files.
///
/// It receives the [ShutdownSignal] that arrived and decides what it
/// means; a hook that only cares about the end of the program returns at
/// once on a signal that does not end it.
typedef ShutdownHook = FutureOr<void> Function(ShutdownSignal signal);
