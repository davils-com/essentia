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

import 'package:essentia_core/essentia_core.dart';

import 'console.dart';
import 'console_dto.dart';

/// Writes a [Console] back into its shape, a mapper as small as a pairing
/// allows.
final class ConsoleMapper implements Mapper<Console, ConsoleDto> {
  /// Creates the mapper.
  const ConsoleMapper();

  /// Maps [domain] onto its transport shape.
  @override
  ConsoleDto fromDomain(Console domain) =>
      ConsoleDto(domain.name, colour: domain.colour);
}
