/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:convert';

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_io/essentia_io.dart';

/// A channel whose writer, a coroutine of [scope], hands over [chunks] one
/// at a time, each in its own flush, and closes it.
///
/// Returns the channel.
ByteChannel arrivingChannel(CoroutineScope scope, List<List<int>> chunks) {
  final channel = ByteChannel();
  scope.launch((it) async {
    for (final chunk in chunks) {
      await channel.writeFully(chunk);
      await channel.flush();
      await yieldNow();
    }
    await channel.flushAndClose();
  });
  return channel;
}

/// A channel that hands over the UTF-8 of [texts] one at a time, as
/// [arrivingChannel] does.
///
/// Returns the channel.
ByteChannel arrivingText(CoroutineScope scope, List<String> texts) =>
    arrivingChannel(scope, [
      for (final String text in texts) utf8.encode(text),
    ]);
