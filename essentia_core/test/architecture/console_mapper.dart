/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

import 'console.dart';
import 'console_dto.dart';

/// Writes a [Console] back into its shape, a mapper as small as a pairing
/// allows.
final class ConsoleMapper implements Mapper<Console, ConsoleDto> {
  /// Creates the mapper.
  const ConsoleMapper();

  /// Maps [domain] onto its transport shape.
  @override
  ConsoleDto fromDomain(Console domain) =>
      ConsoleDto(domain.name, colour: domain.colour);
}
