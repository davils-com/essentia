/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/text/string_blankness.dart';
import 'package:meta/meta.dart';

/// What else is known about a caller: the claims of the token that
/// established it, an e-mail address, the issuer of a subject.
///
/// Names are matched exactly, case included, because that is how token
/// claims are named - `sub` and `Sub` are two claims. Values are text; a
/// structured claim is the edge's to flatten.
///
/// ## Sensitive values
///
/// An attribute can be marked sensitive, and its value is then replaced by
/// `****` wherever Essentia renders it - the attributes' own [toString], and
/// every `Principal` that carries them. Personal data and anything that
/// works as a credential belongs here: an e-mail address is the first, a
/// raw access token the second, and a principal is exactly the object that
/// ends up in a log line. The value is still returned by `[]`, because code
/// that asked for it by name is entitled to it.
///
/// Instances are immutable, at runtime as well as in the type: [names]
/// refuses every mutation, and [withAttribute] and [withoutAttribute] return
/// a new set.
@immutable
final class PrincipalAttributes {
  /// Creates attributes holding [_values], of which the names in
  /// [_sensitive] are masked.
  const PrincipalAttributes._(this._values, this._sensitive);

  /// Attributes from name-value [entries], none of them sensitive.
  ///
  /// Mark a sensitive one with [withAttribute] on the result, which is
  /// deliberately the longer road: a value that has to be masked is worth
  /// one more line where it is set.
  ///
  /// Throws an [ArgumentError] if any name is blank.
  factory PrincipalAttributes.of(Map<String, String> entries) {
    entries.keys.forEach(_requireName);
    return PrincipalAttributes._(
      Map<String, String>.unmodifiable(entries),
      const <String>{},
    );
  }

  /// No attributes at all.
  static const empty = PrincipalAttributes._(<String, String>{}, <String>{});

  /// What a masked value is rendered as.
  static const _mask = '****';

  /// The values by name.
  final Map<String, String> _values;

  /// The names whose values are masked.
  final Set<String> _sensitive;

  /// The names present.
  Set<String> get names => Set<String>.unmodifiable(_values.keys);

  /// Whether nothing is set.
  bool get isEmpty => _values.isEmpty;

  /// Reads the attribute [name], matched exactly, unmasked.
  ///
  /// Returns the value, or `null` when the attribute is not set.
  String? operator [](String name) => _values[name];

  /// Whether the attribute [name], matched exactly, is set.
  ///
  /// Returns `true` when it is set, even to an empty value.
  bool contains(String name) => _values.containsKey(name);

  /// Whether the value of the attribute [name] is masked wherever Essentia
  /// renders it.
  ///
  /// Returns `true` when it was set as sensitive.
  bool isSensitive(String name) => _sensitive.contains(name);

  /// These attributes with [name] set to [value], replacing it if it was
  /// already there.
  ///
  /// [sensitive] masks the value wherever Essentia renders it. Setting an
  /// attribute again replaces its sensitivity too - say it both times.
  ///
  /// Returns a new set of attributes.
  ///
  /// Throws an [ArgumentError] if [name] is blank.
  PrincipalAttributes withAttribute(
    String name,
    String value, {
    bool sensitive = false,
  }) {
    _requireName(name);
    final values = <String, String>{..._values, name: value};
    final masked = <String>{
      for (final String entry in _sensitive)
        if (entry != name) entry,
      if (sensitive) name,
    };
    return PrincipalAttributes._(
      Map<String, String>.unmodifiable(values),
      Set<String>.unmodifiable(masked),
    );
  }

  /// These attributes with [name] removed.
  ///
  /// Removing one that is not set changes nothing.
  ///
  /// Returns a new set of attributes, or this one when [name] is not set.
  PrincipalAttributes withoutAttribute(String name) {
    if (!_values.containsKey(name)) {
      return this;
    }
    return PrincipalAttributes._(
      Map<String, String>.unmodifiable(<String, String>{
        for (final MapEntry<String, String> entry in _values.entries)
          if (entry.key != name) entry.key: entry.value,
      }),
      Set<String>.unmodifiable(_sensitive.where((entry) => entry != name)),
    );
  }

  /// Two sets of attributes are equal when they hold the same values and
  /// mask the same names.
  @override
  bool operator ==(Object other) =>
      other is PrincipalAttributes &&
      _sameValues(other._values) &&
      _sensitive.length == other._sensitive.length &&
      _sensitive.containsAll(other._sensitive);

  /// The hash of the values and the masked names.
  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(
      _values.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
    Object.hashAllUnordered(_sensitive),
  );

  /// Renders the attributes sorted by name, with sensitive values masked:
  /// `{email=****, issuer=idp}`.
  @override
  String toString() {
    final List<String> sorted = _values.keys.toList()..sort();
    final Iterable<String> rendered = sorted.map((name) {
      final String value = _sensitive.contains(name) ? _mask : _values[name]!;
      return '$name=$value';
    });
    return '{${rendered.join(', ')}}';
  }

  /// Whether [others] holds exactly the values of these attributes.
  ///
  /// Returns `true` when both hold the same names with the same values.
  bool _sameValues(Map<String, String> others) {
    if (others.length != _values.length) {
      return false;
    }
    return _values.entries.every(
      (entry) =>
          others.containsKey(entry.key) && others[entry.key] == entry.value,
    );
  }

  /// Refuses a blank attribute [name].
  ///
  /// Throws an [ArgumentError] if [name] is blank.
  static void _requireName(String name) {
    if (name.isBlank) {
      throw ArgumentError.value(
        name,
        'name',
        'An attribute name must not be blank',
      );
    }
  }
}
