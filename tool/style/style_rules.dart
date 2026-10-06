/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:inspectra/style.dart';

import 'no_late_rule.dart';

/// The custom style rules of Essentia, run by `inspectra style` on top of
/// the `strict` preset.
final styleRules = <StyleRule>[const NoLateRule()];
