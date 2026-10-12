/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

/// Where records go, a domain hierarchy for the covariance tests.
class Destination implements DomainModel {
  /// Creates the destination [name].
  const Destination(this.name);

  /// The name of the destination.
  final String name;
}
