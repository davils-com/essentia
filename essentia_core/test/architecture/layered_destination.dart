/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

import 'destination.dart';

/// A type that carries every marker beside a supertype of its own, and
/// implements nothing for them, because the markers declare nothing.
final class LayeredDestination extends Destination
    implements DataSource, Repository<Destination> {
  /// Creates the destination [name].
  const LayeredDestination(super.name);
}
