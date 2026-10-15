/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_io/src/channel/byte_write_channel.dart';

/// The scope of a writer coroutine, Ktor's `WriterScope`: it writes to
/// [channel].
final class WriterScope implements CoroutineScope {
  /// Creates the scope that writes to [channel] in [coroutineContext].
  WriterScope(this.channel, this.coroutineContext);

  /// The channel the coroutine writes to.
  final ByteWriteChannel channel;

  /// The context of the coroutine.
  @override
  final CoroutineContext coroutineContext;
}
