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

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:test/test.dart';

/// Walks the chain of causes that starts at [failure].
///
/// Returns every failure of the chain, [failure] first.
List<Object> _chain(Object failure) {
  final chain = <Object>[failure];
  var current = failure;
  while (current is Causal) {
    final Object? next = current.cause;
    if (next == null) {
      return chain;
    }
    chain.add(next);
    current = next;
  }
  return chain;
}

/// Covers `Causal`: the failures of Essentia that keep the failure behind
/// them, and the chain they form.
void main() {
  final cause = StateError('root');

  test('a cancellation keeps its cause without a stack trace', () {
    final Causal causal = CancellationException('stopped', cause);

    expect(causal.cause, same(cause));
    expect(causal.causeStackTrace, isNull);
    expect(const CancellationException().cause, isNull);
  });

  test('a job cancellation is a causal cancellation', () {
    final Causal causal = JobCancellationException('cancelled', cause: cause);

    expect(causal.cause, same(cause));
    expect(causal.causeStackTrace, isNull);
  });

  test('a failed completion handler keeps where its cause was thrown', () {
    final StackTrace stackTrace = StackTrace.current;
    final Causal causal = CompletionHandlerException(cause, stackTrace);

    expect(causal.cause, same(cause));
    expect(causal.causeStackTrace, same(stackTrace));
  });

  test('a conversion exception keeps its cause', () {
    const format = FormatException('not a number');
    const Causal causal = ConversionException('is not a number', format);

    expect(causal.cause, same(format));
    expect(causal.causeStackTrace, isNull);
    expect(const ConversionException('is not a number').cause, isNull);
  });

  test('a closed channel keeps the cause it was closed with', () {
    final Causal causal = ChannelClosed<int>(cause);

    expect(causal.cause, same(cause));
    expect(causal.causeStackTrace, isNull);
    expect(const ChannelClosed<int>(null).cause, isNull);
  });

  test('a body that cannot be sent keeps what sending it threw', () {
    final Causal body = IsolateBodyNotSendableError.body(cause);
    final Causal result = IsolateBodyNotSendableError.result();

    expect(body.cause, same(cause));
    expect(body.causeStackTrace, isNull);
    expect(result.cause, isNull);
    expect(result.causeStackTrace, isNull);
  });

  test('forms a chain that ends at the first failure without a cause', () {
    final inner = ConversionException('is not a port', cause);
    final outer = CancellationException('gave up', inner);

    expect(_chain(outer), <Object>[outer, inner, cause]);
  });
}
