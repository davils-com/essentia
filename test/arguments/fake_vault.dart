/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

/// A value source answering from a fixed map keyed by primary name, which
/// remembers what it was asked for.
final class FakeVault implements ValueSource {
  /// Creates the source reported as [name], answering from [_entries].
  FakeVault(this._entries, {this.name = 'vault'});

  /// The values by primary name.
  final Map<String, String> _entries;

  /// The primary names this source was asked for, in order.
  final asked = <String>[];

  /// The name the source is reported under.
  @override
  final String name;

  /// Answers from the entries and records the question.
  @override
  Future<String?> read(ParameterInfo parameter) {
    asked.add(parameter.primaryName);
    return Future<String?>.value(_entries[parameter.primaryName]);
  }
}
