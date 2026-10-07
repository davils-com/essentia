/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/channels/send_channel.dart';
import 'package:essentia/src/coroutines/coroutine_scope.dart';

/// The scope the body of `produce` runs in, Kotlin's `ProducerScope`: a
/// coroutine scope that is also the sending side of the channel it fills.
///
/// ```dart
/// final ReceiveChannel<int> squares = scope.produce((it) async {
///   for (var x = 1; x <= 5; x++) {
///     await it.send(x * x);
///   }
/// });
/// ```
abstract interface class ProducerScope<E>
    implements CoroutineScope, SendChannel<E> {
  /// The channel the producer sends to, Kotlin's `ProducerScope.channel`.
  SendChannel<E> get channel;
}
