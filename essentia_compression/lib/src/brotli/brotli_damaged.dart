/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Fails decoding Brotli data that breaks RFC 7932 as [reason] says.
///
/// Throws the [FormatException].
@internal
Never brotliDamaged(String reason) =>
    throw FormatException('The brotli data is damaged: $reason');
