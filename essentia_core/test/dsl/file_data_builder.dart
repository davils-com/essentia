/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

import 'destination_data.dart';

/// Assembles a [FileData].
final class FileDataBuilder extends ValidatingBuilder<FileData> {
  /// The name of the destination.
  var name = 'file';

  /// How large the file may grow.
  var maxBytes = 1024;

  /// Assembles the destination.
  @override
  FileData assemble() => FileData(name, maxBytes);
}
