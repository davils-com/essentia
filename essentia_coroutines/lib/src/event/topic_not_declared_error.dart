/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// A key was resolved against a bus that does not carry the topic it names.
///
/// There is only one way to reach this: using a key declared for one bus
/// against a different bus. It is a defect in how the program is wired
/// rather than anything a caller passed in, so the message names what was
/// asked for and what is actually there.
final class TopicNotDeclaredError extends ArgumentError {
  /// Creates the error for the topic [topicName] on a bus carrying
  /// [declared].
  @internal
  TopicNotDeclaredError(this.topicName, Set<String> declared)
    : declared = Set<String>.unmodifiable(declared),
      super(
        'Topic "$topicName" is not declared on this bus, which carries '
        '${_render(declared)}. A key belongs to the bus whose declaration '
        'carries its topic.',
      );

  /// The name the key carries.
  final String topicName;

  /// The names the bus does carry.
  final Set<String> declared;

  /// Lists [declared] for the message.
  ///
  /// Returns the quoted names in brackets, or `no topics`.
  static String _render(Set<String> declared) {
    if (declared.isEmpty) {
      return 'no topics';
    }
    return '[${declared.map((name) => '"$name"').join(', ')}]';
  }
}
