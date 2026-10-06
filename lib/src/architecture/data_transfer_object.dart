/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/architecture/domain_model.dart';

/// A shape data has while it is in transit, together with how it becomes
/// the domain value [D] it stands for.
///
/// A transport shape is decided by whoever is on the other side of the
/// wire: nullable where the schema is nullable, a `String` where the domain
/// has an enum, flat where the domain is nested. A [DomainModel] is decided
/// by the program. Keeping them as two types is what stops a rename in
/// somebody else's JSON schema from reaching the code that reasons about the
/// value, and [toDomain] is the one place the two vocabularies meet.
///
/// ```dart
/// final class WorkspaceDto implements DataTransferObject<Workspace> {
///   const WorkspaceDto(this.id, this.name);
///
///   final String id;
///   final String name;
///
///   @override
///   Workspace toDomain() => Workspace(WorkspaceId(id), name);
/// }
/// ```
///
/// [D] is bounded by [DomainModel], so a transport shape cannot be declared
/// without a domain type to point at, and it is covariant, so a
/// `List<WorkspaceDto>` is usable where a
/// `List<DataTransferObject<Workspace>>` is expected.
///
/// ## Only one layer may hold one
///
/// A transfer object belongs to a `DataSource` and to the `Repository`
/// that maps it. Handing one to a `UseCase` moves the mapping to whoever
/// called, and then every caller does it, slightly differently. Writing
/// goes the other way and lives on a `Mapper` bound to this pairing.
///
/// ## Malformed data at the boundary
///
/// [toDomain] is total: it maps, and it neither checks nor throws. A
/// transport shape carrying data that may be wrong states what it requires
/// by also implementing `Validatable`, so that one report lists every
/// problem:
///
/// ```dart
/// final Workspace workspace = dto.validateOrThrow('workspace').toDomain();
/// ```
abstract interface class DataTransferObject<D extends DomainModel> {
  /// Maps this transport shape onto the domain value it stands for.
  ///
  /// Implementations map and do nothing else. Validate first, rather than
  /// checking here, so that a shape with several problems reports all of
  /// them instead of the first one.
  ///
  /// Returns the domain value.
  D toDomain();
}
