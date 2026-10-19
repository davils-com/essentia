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
import 'package:meta/meta.dart';

import 'workspace.dart';
import 'workspace_id.dart';

/// The transport shape of a [Workspace], which states what it requires.
@immutable
final class WorkspaceDto implements DataTransferObject<Workspace>, Validatable {
  /// Creates the shape carrying [id], [name] and [owner].
  const WorkspaceDto(this.id, this.name, this.owner);

  /// The longest name a workspace may have.
  static const maxNameLength = 32;

  /// The identifier.
  final String id;

  /// What the workspace is called.
  final String name;

  /// Who owns the workspace.
  final String owner;

  /// States what is wrong with the shape.
  @override
  void validate(ValidationScope scope) {
    if (id.trim().isEmpty) {
      scope.fail('must not be blank', property: 'id');
    }
    if (name.length > maxNameLength) {
      scope.fail('must be at most $maxNameLength characters', property: 'name');
    }
    if (owner.trim().isEmpty) {
      scope.fail('must not be blank', property: 'owner');
    }
  }

  /// Maps the shape onto the workspace it stands for.
  @override
  Workspace toDomain() => Workspace(WorkspaceId(id), name, owner);

  /// Two shapes are equal when their parts are.
  @override
  bool operator ==(Object other) =>
      other is WorkspaceDto &&
      id == other.id &&
      name == other.name &&
      owner == other.owner;

  /// The hash of the parts.
  @override
  int get hashCode => Object.hash(id, name, owner);

  /// Renders the shape for a failure message.
  @override
  String toString() => 'WorkspaceDto(id=$id, name=$name, owner=$owner)';
}
