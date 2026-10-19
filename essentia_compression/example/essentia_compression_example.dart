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

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:essentia_compression/essentia_compression.dart';

/// Compresses a text with gzip, reads it back and prints its CRC-32.
Future<void> main() async {
  final List<int> text = utf8.encode('hello world hello world');
  final Uint8List compressed = await gzip(text);
  final Uint8List restored = await gunzip(compressed);

  stdout
    ..writeln('${text.length} bytes -> ${compressed.length} bytes')
    ..writeln(utf8.decode(restored))
    ..writeln('CRC-32: ${Crc32.of(text).toRadixString(16)}');
}
