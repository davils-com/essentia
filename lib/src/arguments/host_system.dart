/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// What the program parameters need from the host: its environment and its
/// file system, read through `dart:io` where the platform has it and
/// answered without it everywhere else, the web included.
library;

export 'package:essentia/src/arguments/host_system_web.dart'
    if (dart.library.io) 'package:essentia/src/arguments/host_system_io.dart';
