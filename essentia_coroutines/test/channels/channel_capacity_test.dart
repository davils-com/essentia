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
import 'package:test/test.dart';

/// Sends `0` to `count - 1` to [channel] without waiting.
///
/// Returns the results, in order.
List<ChannelResult<void>> _fill(SendChannel<int> channel, int count) => [
  for (var element = 0; element < count; element++) channel.trySend(element),
];

/// Receives everything [channel] holds without waiting.
///
/// Returns the elements, in order.
List<int> _drain(ReceiveChannel<int> channel) {
  final elements = <int>[];
  while (true) {
    final ChannelResult<int> result = channel.tryReceive();
    if (!result.isSuccess) {
      return elements;
    }
    elements.add(result.getOrThrow());
  }
}

/// Covers how `Channel()` resolves its capacity and overflow policy.
void main() {
  test('names the capacities with their fixed values', () {
    expect(Channel.rendezvous, 0);
    expect(Channel.conflated, -1);
    expect(Channel.buffered, -2);
    expect(Channel.unlimited, 0x7fffffff);
    expect(Channel.defaultCapacity, 64);
  });

  test('a rendezvous channel buffers nothing', () {
    final channel = Channel<int>();

    expect(channel.trySend(1), const ChannelFailure<void>());
    expect(channel.isEmpty, isTrue);
  });

  test('a buffered channel holds the default capacity', () {
    final channel = Channel<int>(capacity: Channel.buffered);

    final List<ChannelResult<void>> results = _fill(channel, 65);

    expect(results.where((result) => result.isSuccess), hasLength(64));
    expect(results.last, const ChannelFailure<void>());
  });

  test('an unlimited channel never refuses an element', () {
    final channel = Channel<int>(capacity: Channel.unlimited);

    final List<ChannelResult<void>> results = _fill(channel, 1000);

    expect(results.every((result) => result.isSuccess), isTrue);
    expect(_drain(channel), List<int>.generate(1000, (index) => index));
  });

  test('an unlimited channel ignores the overflow policy', () {
    final channel = Channel<int>(
      capacity: Channel.unlimited,
      onBufferOverflow: BufferOverflow.dropLatest,
    );

    _fill(channel, 100);

    expect(_drain(channel), hasLength(100));
  });

  test('a conflated channel keeps the newest element only', () {
    final dropped = <int>[];
    final channel = Channel<int>(
      capacity: Channel.conflated,
      onUndeliveredElement: dropped.add,
    );

    final List<ChannelResult<void>> results = _fill(channel, 3);

    expect(results.every((result) => result.isSuccess), isTrue);
    expect(_drain(channel), <int>[2]);
    expect(dropped, <int>[0, 1]);
  });

  test('a conflated channel takes no overflow policy', () {
    expect(
      () => Channel<int>(
        capacity: Channel.conflated,
        onBufferOverflow: BufferOverflow.dropLatest,
      ),
      throwsArgumentError,
    );
  });

  test('refuses a negative capacity that names no kind of channel', () {
    expect(() => Channel<int>(capacity: -3), throwsArgumentError);
  });

  test('a rendezvous channel that drops buffers one element', () {
    final channel = Channel<int>(onBufferOverflow: BufferOverflow.dropOldest);

    _fill(channel, 3);

    expect(_drain(channel), <int>[2]);
  });

  test('a buffered channel that drops buffers one element', () {
    final channel = Channel<int>(
      capacity: Channel.buffered,
      onBufferOverflow: BufferOverflow.dropLatest,
    );

    _fill(channel, 3);

    expect(_drain(channel), <int>[0]);
  });

  test('dropping the oldest element reports it and keeps the order', () {
    final dropped = <int>[];
    final channel = Channel<int>(
      capacity: 2,
      onBufferOverflow: BufferOverflow.dropOldest,
      onUndeliveredElement: dropped.add,
    );

    _fill(channel, 5);

    expect(_drain(channel), <int>[3, 4]);
    expect(dropped, <int>[0, 1, 2]);
  });

  test('dropping the latest element reports it for a send only', () async {
    final dropped = <int>[];
    final channel = Channel<int>(
      capacity: 1,
      onBufferOverflow: BufferOverflow.dropLatest,
      onUndeliveredElement: dropped.add,
    );

    final List<ChannelResult<void>> results = _fill(channel, 2);
    await channel.send(7);

    expect(results, everyElement(const ChannelSuccess<void>(null)));
    expect(dropped, <int>[7]);
    expect(_drain(channel), <int>[0]);
  });

  test('a channel of a fixed capacity refuses once it is full', () {
    final channel = Channel<int>(capacity: 3);

    final List<ChannelResult<void>> results = _fill(channel, 4);

    expect(results.map((result) => result.isSuccess), <bool>[
      true,
      true,
      true,
      false,
    ]);
    expect(_drain(channel), <int>[0, 1, 2]);
  });
}
