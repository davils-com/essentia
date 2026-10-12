/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

import 'workspace_id.dart';

/// What renaming a workspace needs.
@immutable
final class RenameWorkspaceInput {
  /// Creates the input renaming [id] to [name].
  const RenameWorkspaceInput(this.id, this.name);

  /// The workspace to rename.
  final WorkspaceId id;

  /// The new name.
  final String name;
}
