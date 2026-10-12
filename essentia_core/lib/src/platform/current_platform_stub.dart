/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/platform/platform.dart';
import 'package:meta/meta.dart';

/// Reads the platform on a runtime that offers no way to ask.
///
/// Returns `null`, because nothing can be named.
@internal
Platform? currentPlatform() => null;
