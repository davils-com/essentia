/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/collection/window_remainder.dart';
import 'package:meta/meta.dart';

/// The size of a window, how far each next window starts after the one
/// before, and what happens to the partial windows at the end.
@internal
typedef WindowShape = ({int size, int step, WindowRemainder remainder});
