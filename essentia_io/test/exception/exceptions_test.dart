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
import 'package:essentia_io/essentia_io.dart';
import 'package:test/test.dart';

/// Covers the exceptions of essentia_io: their names, messages and causes.
void main() {
  test('names each exception in its description', () {
    expect(const IoException('broken').toString(), 'IoException: broken');
    expect(const EofException('short').toString(), 'EofException: short');
    expect(
      const ConnectionClosedException().toString(),
      'ConnectionClosedException: Connection was closed',
    );
    expect(
      const TooLongLineException('long').toString(),
      'TooLongLineException: long',
    );
    expect(
      ClosedByteChannelException().toString(),
      'ClosedByteChannelException: The channel was closed',
    );
    expect(
      ClosedReadChannelException().toString(),
      'ClosedReadChannelException: The channel was closed',
    );
    expect(
      ClosedWriteChannelException().toString(),
      'ClosedWriteChannelException: The channel was closed',
    );
  });

  test('takes the message of an input or output cause and hides others', () {
    final StackTrace trace = StackTrace.current;

    final fromIo = ClosedReadChannelException(const EofException('cut'), trace);
    final fromOther = ClosedWriteChannelException(StateError('secret'));

    expect(fromIo.message, 'cut');
    expect(fromIo.cause, isA<EofException>());
    expect(fromIo.causeStackTrace, same(trace));
    expect(fromOther.message, 'The channel was cancelled');
    expect(fromOther.toString(), isNot(contains('secret')));
  });

  test('says which attempt ran twice', () {
    final error = ConcurrentIoException('read');

    expect(error.task, 'read');
    expect(error.message, 'Concurrent read attempts');
  });

  test('carries a cause', () {
    const cause = CancellationException('stop');

    const exception = IoException('failed', cause: cause);

    expect(exception.cause, same(cause));
    expect(exception.causeStackTrace, isNull);
  });
}
