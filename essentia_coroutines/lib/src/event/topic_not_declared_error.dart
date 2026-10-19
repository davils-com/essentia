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
