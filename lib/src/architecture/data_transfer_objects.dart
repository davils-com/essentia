/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/architecture/data_transfer_object.dart';
import 'package:essentia/src/architecture/domain_model.dart';

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
