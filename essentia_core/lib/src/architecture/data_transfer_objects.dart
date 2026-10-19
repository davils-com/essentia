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

/// Maps a whole collection of transport shapes, which is what a repository
/// does with the answer a data source handed it.
///
/// ```dart
/// Future<List<Workspace>> all() async =>
///     (await _source.findAll()).toDomain();
/// ```
extension DataTransferObjects<D extends DomainModel>
    on Iterable<DataTransferObject<D>> {
  /// Maps every transport shape onto the domain value of type [D] it stands
  /// for.
  ///
  /// Returns the domain values, in the order the shapes were in.
  List<D> toDomain() => <D>[for (final shape in this) shape.toDomain()];
}
