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

/// Two keys name one topic and disagree about what it carries.
///
/// A key is an ordinary value, so nothing stops an application writing
/// down `TopicKey<UserEvent>('users')` in one place and
/// `TopicKey<AuditEvent>('users')` in another. One of them is wrong, and
/// this says which topic they are arguing over and what each of them
/// thinks.
///
/// Raised where the key is resolved rather than where it is used, so the
/// report points at the two declarations that contradict each other instead
/// of at a consumer that receives something it cannot handle.
final class TopicTypeMismatchError extends ArgumentError {
  /// Creates the error for the topic [topicName], declared to carry
  /// [declared] and resolved with a key expecting [requested].
  @internal
  TopicTypeMismatchError(this.topicName, this.declared, this.requested)
    : super(
        'Topic "$topicName" carries $declared but was resolved with a key '
        'expecting $requested. Two keys name this topic and disagree; one '
        'of them is wrong.',
      );

  /// The topic both keys name.
  final String topicName;

  /// What the topic was declared to carry.
  final Type declared;

  /// What the key that was resolved expected it to carry.
  final Type requested;
}
