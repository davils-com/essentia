/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:meta/meta.dart';

import 'console.dart';

/// The transport shape of a [Console].
@immutable
final class ConsoleDto implements DataTransferObject<Console> {
  /// Creates the shape of the console [name].
  const ConsoleDto(this.name, {required this.colour});

  /// The name of the console.
  final String name;

  /// Whether records are written in colour.
  final bool colour;

  /// Maps the shape onto the console it stands for.
  @override
  Console toDomain() => Console(name, colour: colour);

  /// Two shapes are equal when their parts are.
  @override
  bool operator ==(Object other) =>
      other is ConsoleDto && name == other.name && colour == other.colour;

  /// The hash of the parts.
  @override
  int get hashCode => Object.hash(name, colour);

  /// Renders the shape for a failure message.
  @override
  String toString() => 'ConsoleDto(name=$name, colour=$colour)';
}
