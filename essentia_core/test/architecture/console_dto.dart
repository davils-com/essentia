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
import 'package:meta/meta.dart';

import 'console.dart';

/// The transport shape of a [Console].
@immutable
final class ConsoleDto implements DataTransferObject<Console> {
  /// Creates the shape of the console [name].
  const ConsoleDto(this.name, {required this.colour});

  /// The name of the console.
  final String name;

  /// Whether records are written in colour.
  final bool colour;

  /// Maps the shape onto the console it stands for.
  @override
  Console toDomain() => Console(name, colour: colour);

  /// Two shapes are equal when their parts are.
  @override
  bool operator ==(Object other) =>
      other is ConsoleDto && name == other.name && colour == other.colour;

  /// The hash of the parts.
  @override
  int get hashCode => Object.hash(name, colour);

  /// Renders the shape for a failure message.
  @override
  String toString() => 'ConsoleDto(name=$name, colour=$colour)';
}
