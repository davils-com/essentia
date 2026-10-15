/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// The key of a value of type [T] in [Attributes], Ktor's
/// `AttributeKey`.
///
/// Two keys are equal when their names and types are, as in Ktor, so a
/// key may be created where it is needed; a key is usually a top level
/// constant of the code that owns the value.
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

  /// Describes the key, as Ktor does.
  ///
  /// Returns `AttributeKey: <name>`.
  @override
  String toString() => 'AttributeKey: $name';
}
