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

import 'package:essentia_core/src/charset/charset.dart';
import 'package:meta/meta.dart';

/// A charset made of an [encoder] and a [decoder].
@internal
final class BuiltCharset extends Charset {
  /// Creates the charset [name], also known as [aliases], that encodes with
  /// [encoder] and decodes with [decoder].
  const BuiltCharset(super.name, super.aliases, this.encoder, this.decoder);

  /// Turns text into bytes.
  @override
  final Converter<String, List<int>> encoder;

  /// Turns bytes into text.
  @override
  final Converter<List<int>, String> decoder;
}
