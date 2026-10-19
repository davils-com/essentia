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
import 'dart:typed_data';

import 'package:essentia_compression/src/brotli/brotli_dictionary_data.dart';
import 'package:meta/meta.dart';

/// The static dictionary of Brotli, RFC 7932 Appendix A, decoded the first
/// time a stream refers to it.
@internal
final Uint8List brotliDictionary = base64.decode(brotliDictionaryData);
