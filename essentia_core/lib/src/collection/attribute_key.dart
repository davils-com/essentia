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

/// The key of a value of type [T] in [Attributes].
///
/// Two keys are equal when their names and types are, so a key may be
/// created where it is needed; a key is usually a top level constant of
/// the code that owns the value.
///
/// ```dart
/// const requestId = AttributeKey<String>('RequestId');
/// attributes.put(requestId, 'a1b2');
/// final String id = attributes.get(requestId);
/// ```
///
/// [Attributes]: package:essentia_core/essentia_core.dart
@immutable
final class AttributeKey<T extends Object> {
  /// Creates the key [name] of a value of type [T].
  const AttributeKey(this.name);

  /// The name, which together with [T] identifies the key.
  final String name;

  /// The type of the value under the key.
  Type get type => T;

  /// Whether [value] may be stored under this key.
  ///
  /// Returns `true` when [value] is a [T].
  bool accepts(Object value) => value is T;

  /// Whether [other] is a key of the same name and type.
  ///
  /// Returns `true` when it is.
  @override
  bool operator ==(Object other) =>
      other is AttributeKey<Object> && other.name == name && other.type == T;

  /// A hash of the name and the type.
  @override
  int get hashCode => Object.hash(name, T);

  /// Describes the key.
  ///
  /// Returns `AttributeKey: <name>`.
  @override
  String toString() => 'AttributeKey: $name';
}
