/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// The out-of-band values that travel beside an event.
///
/// Headers are what a concern that is not the domain's puts on an envelope:
/// a trace parent, the tenant a request came in for, the name of the
/// service that published it. The payload stays about what happened, and a
/// subscriber that does not care about any of this never sees it.
///
/// Names are matched without regard to case and are held lowercase, so a
/// header written as `Traceparent` by one library and read as
/// `traceparent` by another is one header rather than two.
///
/// Instances are immutable. [withHeader] and [withoutHeader] return a new
/// set rather than changing this one, which is what makes an envelope safe
/// to hand to several subscribers at once.
///
/// A header can be marked sensitive, in which case its value is replaced by
/// `****` wherever Essentia renders it, including in a failure that is
/// about that very envelope.
@immutable
final class EventHeaders {
  /// Creates headers holding [_values], of which the names in [_sensitive]
  /// are masked.
  const EventHeaders._(this._values, this._sensitive);

  /// Builds a set of headers from [entries], none of them sensitive.
  ///
  /// Mark a sensitive one by calling [withHeader] on the result, which is
  /// deliberately the longer road: a value that has to be masked is worth
  /// one more line at the place it is set. Names that differ only in case
  /// keep the value given last.
  ///
  /// Throws an [ArgumentError] if any name is blank.
  factory EventHeaders.of(Map<String, String> entries) {
    if (entries.isEmpty) {
      return empty;
    }
    final values = <String, String>{};
    for (final MapEntry<String, String> entry in entries.entries) {
      _requireName(entry.key);
      values[entry.key.toLowerCase()] = entry.value;
    }
    return EventHeaders._(
      Map<String, String>.unmodifiable(values),
      const <String>{},
    );
  }

  /// The set with nothing in it, which is what an envelope carries unless
  /// something adds to it.
  static const empty = EventHeaders._(<String, String>{}, <String>{});

  /// What a masked value is rendered as.
  static const _mask = '****';

  /// The values by lowercase name.
  final Map<String, String> _values;

  /// The lowercase names whose values are masked.
  final Set<String> _sensitive;

  /// The names present, lowercase.
  Set<String> get names => Set<String>.unmodifiable(_values.keys);

  /// Whether nothing is set.
  bool get isEmpty => _values.isEmpty;

  /// Reads the header [name], matched without regard to case.
  ///
  /// The value is returned as it was set, unmasked, because a subscriber
  /// that asked for it by name is entitled to it. Masking applies to what
  /// Essentia renders, not to what it hands back.
  ///
  /// Returns the value, or `null` if the header is not set.
  String? operator [](String name) => _values[name.toLowerCase()];

  /// Whether the header [name] is set, even to an empty value.
  bool contains(String name) => _values.containsKey(name.toLowerCase());

  /// Whether the value of the header [name] is masked wherever Essentia
  /// renders it.
  bool isSensitive(String name) => _sensitive.contains(name.toLowerCase());

  /// Returns these headers with [name] set to [value], replacing it if it
  /// was already there.
  ///
  /// [sensitive] masks the value wherever Essentia renders it. Setting a
  /// header again replaces this too, so a header set sensitive and then set
  /// again without saying so is no longer masked: say it both times.
  ///
  /// Throws an [ArgumentError] if [name] is blank.
  EventHeaders withHeader(String name, String value, {bool sensitive = false}) {
    _requireName(name);
    final String key = name.toLowerCase();
    final values = <String, String>{..._values, key: value};
    final masked = <String>{
      for (final String entry in _sensitive)
        if (entry != key) entry,
      if (sensitive) key,
    };
    return EventHeaders._(
      Map<String, String>.unmodifiable(values),
      Set<String>.unmodifiable(masked),
    );
  }

  /// Returns these headers with [name] removed.
  ///
  /// Removing one that is not set changes nothing.
  EventHeaders withoutHeader(String name) {
    final String key = name.toLowerCase();
    if (!_values.containsKey(key)) {
      return this;
    }
    return EventHeaders._(
      Map<String, String>.unmodifiable(<String, String>{
        for (final MapEntry<String, String> entry in _values.entries)
          if (entry.key != key) entry.key: entry.value,
      }),
      Set<String>.unmodifiable(_sensitive.where((entry) => entry != key)),
    );
  }

  /// Returns these headers with everything in [other] set on top of them.
  ///
  /// Where both set the same name, [other] wins, and it brings its own
  /// sensitivity with it.
  EventHeaders operator +(EventHeaders other) {
    if (other.isEmpty) {
      return this;
    }
    if (isEmpty) {
      return other;
    }
    final masked = <String>{
      for (final String entry in _sensitive)
        if (!other._values.containsKey(entry)) entry,
      ...other._sensitive,
    };
    return EventHeaders._(
      Map<String, String>.unmodifiable(<String, String>{
        ..._values,
        ...other._values,
      }),
      Set<String>.unmodifiable(masked),
    );
  }

  /// Two sets of headers are equal when they hold the same values and mask
  /// the same names.
  @override
  bool operator ==(Object other) =>
      other is EventHeaders &&
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

  /// Renders the headers sorted by name, with sensitive values masked:
  /// `{tenant=acme, token=****}`.
  @override
  String toString() {
    final List<String> sorted = _values.keys.toList()..sort();
    final Iterable<String> rendered = sorted.map((name) {
      final String value = _sensitive.contains(name) ? _mask : _values[name]!;
      return '$name=$value';
    });
    return '{${rendered.join(', ')}}';
  }

  /// Whether [others] holds exactly the values of these headers.
  ///
  /// Returns `true` when both hold the same names with the same values.
  bool _sameValues(Map<String, String> others) {
    if (others.length != _values.length) {
      return false;
    }
    return _values.entries.every((entry) => others[entry.key] == entry.value);
  }

  /// Refuses a blank header [name].
  ///
  /// Throws an [ArgumentError] if [name] is blank.
  static void _requireName(String name) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'A header name must not be blank',
      );
    }
  }
}
