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

import 'workspace_id.dart';

/// A workspace, the domain model of the layering tests.
@immutable
final class Workspace implements DomainModel {
  /// Creates the workspace [id] called [name] and owned by [owner].
  const Workspace(this.id, this.name, this.owner);

  /// The identity of the workspace.
  final WorkspaceId id;

  /// What the workspace is called.
  final String name;

  /// Who owns the workspace.
  final String owner;

  /// A copy of this workspace called [newName].
  ///
  /// Returns the renamed copy.
  Workspace renamed(String newName) => Workspace(id, newName, owner);

  /// Two workspaces are equal when their parts are.
  @override
  bool operator ==(Object other) =>
      other is Workspace &&
      id == other.id &&
      name == other.name &&
      owner == other.owner;

  /// The hash of the parts.
  @override
  int get hashCode => Object.hash(id, name, owner);

  /// Renders the workspace for a failure message.
  @override
  String toString() => 'Workspace(id=$id, name=$name, owner=$owner)';
}
