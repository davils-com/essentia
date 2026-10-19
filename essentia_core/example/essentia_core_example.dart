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

import 'dart:io';

import 'package:essentia_core/essentia_core.dart';

/// Checks a version against a range and parses a number safely.
void main() {
  final version = SemanticVersion.parse('1.4.0');
  final range = SemanticVersionRange.parse('^1.2 || >=2.0.0 <2.1.0');
  final Result<int> port = runCatching(() => int.parse('8080'));

  stdout
    ..writeln('$version in $range: ${range.contains(version)}')
    ..writeln('port: ${port.valueOrNull}');
}
