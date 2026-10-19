/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
