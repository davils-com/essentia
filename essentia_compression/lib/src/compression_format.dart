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
