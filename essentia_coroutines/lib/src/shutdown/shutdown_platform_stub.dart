/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/shutdown/shutdown_signal.dart';
import 'package:meta/meta.dart';

/// Watches nothing: a platform without `dart:io` and without a browser
/// tells a program nothing about its end.
///
/// Returns a stream that never emits.
@internal
Stream<ShutdownSignal> watchHostSignals() =>
    const Stream<ShutdownSignal>.empty();

/// Does nothing: the platform does not let a program end itself.
@internal
void exitHost(int code) {}
