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

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_io/src/channel/byte_write_channel.dart';

/// The scope of a writer coroutine: it writes to [channel].
final class WriterScope implements CoroutineScope {
  /// Creates the scope that writes to [channel] in [coroutineContext].
  WriterScope(this.channel, this.coroutineContext);

  /// The channel the coroutine writes to.
  final ByteWriteChannel channel;

  /// The context of the coroutine.
  @override
  final CoroutineContext coroutineContext;
}
