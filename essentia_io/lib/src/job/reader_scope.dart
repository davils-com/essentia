/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_io/src/channel/byte_read_channel.dart';

/// The scope of a reader coroutine: it reads from [channel].
final class ReaderScope implements CoroutineScope {
  /// Creates the scope that reads from [channel] in [coroutineContext].
  ReaderScope(this.channel, this.coroutineContext);

  /// The channel the coroutine reads from.
  final ByteReadChannel channel;

  /// The context of the coroutine.
  @override
  final CoroutineContext coroutineContext;
}
