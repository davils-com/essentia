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
