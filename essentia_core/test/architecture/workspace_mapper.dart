/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

import 'workspace.dart';
import 'workspace_dto.dart';

/// Writes a [Workspace] back into the shape that carries it.
final class WorkspaceMapper implements Mapper<Workspace, WorkspaceDto> {
  /// Creates the mapper.
  const WorkspaceMapper();

  /// Maps [domain] onto its transport shape.
  @override
  WorkspaceDto fromDomain(Workspace domain) =>
      WorkspaceDto(domain.id.value, domain.name, domain.owner);
}
