/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// A container of deflate data, RFC 1951, as the platforms compress it.
@internal
enum CompressionFormat {
  /// One gzip member, RFC 1952.
  gzip('gzip'),

  /// A zlib stream, RFC 1950: what HTTP calls `deflate`.
  zlib('deflate'),

  /// Deflate data without a container, RFC 1951.
  raw('deflate-raw');

  /// Creates the format the browser names [webName].
  const CompressionFormat(this.webName);

  /// The name `CompressionStream` and `DecompressionStream` of the browser
  /// know the format by.
  final String webName;
}
