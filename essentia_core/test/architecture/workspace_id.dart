/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// The identity of a workspace.
@immutable
final class WorkspaceId {
  /// Creates the identity [value].
  const WorkspaceId(this.value);

  /// The identifier.
  final String value;

  /// Two identities are equal when their values are.
  @override
  bool operator ==(Object other) =>
      other is WorkspaceId && value == other.value;

  /// The hash of the value.
  @override
  int get hashCode => value.hashCode;

  /// Renders the identity for a failure message.
  @override
  String toString() => 'WorkspaceId($value)';
}
