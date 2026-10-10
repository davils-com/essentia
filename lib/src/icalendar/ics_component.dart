/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/icalendar/ics_property.dart';
import 'package:meta/meta.dart';

/// A component of an iCalendar file between `BEGIN` and `END`: its
/// [name], its [properties] in order and the [components] nested in it.
@immutable
final class IcsComponent {
  /// The component [name] with [properties] and nested [components].
  IcsComponent(
    String name, {
    List<IcsProperty> properties = const <IcsProperty>[],
    List<IcsComponent> components = const <IcsComponent>[],
  }) : name = name.toUpperCase(),
       properties = List<IcsProperty>.unmodifiable(properties),
       components = List<IcsComponent>.unmodifiable(components);

  /// The name, such as `VEVENT`, in upper case.
  final String name;

  /// The properties, in the order they were written.
  final List<IcsProperty> properties;

  /// The nested components, in the order they were written.
  final List<IcsComponent> components;

  /// The first property named [name], or `null`.
  IcsProperty? property(String name) {
    final String upper = name.toUpperCase();
    for (final IcsProperty property in properties) {
      if (property.name == upper) {
        return property;
      }
    }
    return null;
  }

  /// Every property named [name].
  List<IcsProperty> all(String name) {
    final String upper = name.toUpperCase();
    return <IcsProperty>[
      for (final property in properties)
        if (property.name == upper) property,
    ];
  }

  /// Every nested component named [name].
  List<IcsComponent> children(String name) {
    final String upper = name.toUpperCase();
    return <IcsComponent>[
      for (final component in components)
        if (component.name == upper) component,
    ];
  }

  /// Whether [other] is the same component.
  @override
  bool operator ==(Object other) =>
      other is IcsComponent &&
      other.name == name &&
      _same(other.properties, properties) &&
      _same(other.components, components);

  /// Whether [a] and [b] hold equal elements in order.
  static bool _same(List<Object> a, List<Object> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }

  /// A hash of the component.
  @override
  int get hashCode =>
      Object.hash(name, Object.hashAll(properties), Object.hashAll(components));

  /// Describes the component briefly.
  @override
  String toString() =>
      'IcsComponent($name, ${properties.length} properties, '
      '${components.length} components)';
}
