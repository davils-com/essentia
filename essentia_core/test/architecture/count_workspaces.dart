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

import 'workspace_repository.dart';

/// Counts the workspaces, a use case without an input.
final class CountWorkspaces implements UseCase<void, int> {
  /// Creates the use case counting what [_workspaces] holds.
  const CountWorkspaces(this._workspaces);

  /// Where the workspaces are.
  final WorkspaceRepository _workspaces;

  /// Counts the workspaces.
  @override
  Future<int> call(void input) async => (await _workspaces.all()).length;
}
