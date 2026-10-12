/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// One value as the command line carried it, before conversion.
@internal
@immutable
final class RawOccurrence {
  /// Creates the occurrence of [raw], given through [token].
  const RawOccurrence(this.raw, this.token);

  /// The unconverted value.
  final String raw;

  /// The token that named the parameter.
  final String token;
}
