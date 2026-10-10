/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Where the time zone of the system is read: from the environment and
/// the file system where `dart:io` is, from the browser on the web, and
/// nowhere else.
library;

export 'package:essentia/src/time/current_time_zone_stub.dart'
    if (dart.library.io) 'package:essentia/src/time/current_time_zone_io.dart'
    if (dart.library.js_interop) 'package:essentia/src/time/current_time_zone_web.dart';
