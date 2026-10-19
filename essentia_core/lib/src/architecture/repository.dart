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

import 'package:essentia_core/src/architecture/domain_model.dart';

/// Everything the program can do with one domain model [D], assembled from
/// data sources and handed back in the domain's own types.
///
/// A repository is the seam between the vocabulary of storage and the
/// vocabulary of the program. It owns the mapping in both directions, it is
/// where more than one `DataSource` is coordinated into a single answer,
/// and it is what the rest of the program is written against, so that
/// replacing a local file with a remote service changes one implementation
/// and nothing that calls it.
///
/// ```dart
/// final class WorkspaceRepository implements Repository<Workspace> {
///   const WorkspaceRepository(this._source);
///
///   final WorkspaceDataSource _source;
///
///   Future<List<Workspace>> all() async =>
///       (await _source.findAll()).toDomain();
///
///   Future<bool> save(Workspace workspace) =>
///       _source.upsert(const WorkspaceMapper().fromDomain(workspace));
/// }
/// ```
///
/// ## One repository, one subject
///
/// [D] names what this repository is for, and it is the reason the
/// parameter exists on a type that declares no members: a repository that
/// has to name its subject is a repository somebody has to decide the
/// subject of. When there is no domain model to name, that is the finding,
/// not an obstacle.
///
/// ## What it does not hand back
///
/// Domain types, never `DataTransferObject` instances. Handing a transport
/// shape upward moves the mapping to whoever called, and then every caller
/// does it, slightly differently. Read with `DataTransferObject.toDomain`
/// and write with a `Mapper` for the same pairing.
///
/// Like `DataSource` and [DomainModel], this declares no member. Whatever
/// an implementation needs, its data sources, a clock, a logger, arrives
/// through its constructor.
abstract interface class Repository<D extends DomainModel> {}
