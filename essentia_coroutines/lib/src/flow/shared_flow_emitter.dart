/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
