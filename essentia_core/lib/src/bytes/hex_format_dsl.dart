/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/bytes/hex_format.dart';
import 'package:essentia_core/src/bytes/hex_format_builder.dart';
import 'package:essentia_core/src/scope/scope_functions.dart';

/// Builds a [HexFormat] from a configuration block.
///
/// Returns the format.
HexFormat hexFormat(void Function(HexFormatBuilder it) block) =>
    HexFormatBuilder().apply(block).build();
