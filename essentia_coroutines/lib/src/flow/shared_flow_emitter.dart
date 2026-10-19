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

import 'package:essentia_coroutines/src/continuation/cancellable_continuation.dart';
import 'package:meta/meta.dart';

/// An emitter waiting in the queue of a full shared flow.
@internal
final class SharedFlowEmitter {
  /// Creates the emitter of [value] queued at [index], resumed through
  /// [continuation].
  SharedFlowEmitter({
    required this.index,
    required this.value,
    required this.continuation,
  });

  /// The index of the emitter in the buffer.
  final int index;

  /// The value the emitter waits to emit.
  final Object? value;

  /// Resumes the waiting emitter.
  final CancellableContinuation<void> continuation;
}
