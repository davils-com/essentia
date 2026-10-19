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

import 'package:essentia_core/src/architecture/data_transfer_object.dart';
import 'package:essentia_core/src/architecture/domain_model.dart';

/// The write direction of one pairing: how a domain value [D] becomes the
/// transport shape [T] that carries it.
///
/// [DataTransferObject.toDomain] covers reading, because a shape that
/// arrived knows what it stands for. Writing has nowhere natural to live, a
/// domain model must not know the wire it will be sent over, so it lives
/// here, in a type that is about exactly one pairing.
///
/// ```dart
/// final class WorkspaceMapper implements Mapper<Workspace, WorkspaceDto> {
///   const WorkspaceMapper();
///
///   @override
///   WorkspaceDto fromDomain(Workspace domain) =>
///       WorkspaceDto(domain.id.value, domain.name);
/// }
/// ```
///
/// ## What the type parameters buy
///
/// [T] is bounded by `DataTransferObject<D>`, so a mapper cannot be
/// declared between two types that are not already a reading pair. That is
/// what closes the loop: `toDomain` and [fromDomain] are two halves of one
/// mapping the type checker keeps together.
///
/// ## The round trip
///
/// Where a transport shape carries everything the domain model does, the
/// two halves are expected to undo each other:
/// `mapper.fromDomain(dto.toDomain()) == dto`. That is worth a test per
/// pairing; it catches a field added to both types and wired up in only one
/// of them. Where the two do not carry the same information the law does
/// not hold, and the mapper should say so.
abstract interface class Mapper<
  D extends DomainModel,
  T extends DataTransferObject<D>
> {
  /// Maps [domain] onto the transport shape that carries it.
  ///
  /// Like its counterpart, this maps and does nothing else.
  ///
  /// Returns the transport shape.
  T fromDomain(D domain);
}
