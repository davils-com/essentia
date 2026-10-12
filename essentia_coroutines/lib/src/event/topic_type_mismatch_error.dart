/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
