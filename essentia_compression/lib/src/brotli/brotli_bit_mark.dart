/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Where a `BrotliBitReader` stood: the next byte it loads and the bits it
/// had loaded but not read.
@internal
typedef BrotliBitMark = ({int position, int bits, int bitCount});
