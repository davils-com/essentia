/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
import 'package:meta/meta.dart';

/// Where a pipeline sends its records, the supertype that differently
/// built destinations share.
@immutable
sealed class DestinationData implements Validatable {
  /// Creates the destination [name].
  const DestinationData(this.name);

  /// The name of the destination.
  final String name;

  /// States what is wrong with any destination.
  @override
  void validate(ValidationScope scope) {
    if (name.trim().isEmpty) {
      scope.fail('must not be blank', property: 'name');
    }
  }
}

/// A destination writing to the console.
final class ConsoleData extends DestinationData {
  /// Creates the console destination [name], in colour when [colour] is set.
  const ConsoleData(super.name, {required this.colour});

  /// Whether records are written in colour.
  final bool colour;

  /// Two console destinations are equal when their parts are.
  @override
  bool operator ==(Object other) =>
      other is ConsoleData && name == other.name && colour == other.colour;

  /// The hash of the parts.
  @override
  int get hashCode => Object.hash(ConsoleData, name, colour);

  /// Renders the destination for a failure message.
  @override
  String toString() => 'ConsoleData(name=$name, colour=$colour)';
}

/// A destination writing to a file.
final class FileData extends DestinationData {
  /// Creates the file destination [name] growing to at most [maxBytes].
  const FileData(super.name, this.maxBytes);

  /// How large the file may grow.
  final int maxBytes;

  /// States what is wrong with the file destination.
  @override
  void validate(ValidationScope scope) {
    super.validate(scope);
    if (maxBytes < 1) {
      scope.fail('must be at least 1', property: 'maxBytes');
    }
  }

  /// Two file destinations are equal when their parts are.
  @override
  bool operator ==(Object other) =>
      other is FileData && name == other.name && maxBytes == other.maxBytes;

  /// The hash of the parts.
  @override
  int get hashCode => Object.hash(FileData, name, maxBytes);

  /// Renders the destination for a failure message.
  @override
  String toString() => 'FileData(name=$name, maxBytes=$maxBytes)';
}
