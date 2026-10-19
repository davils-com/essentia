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

import 'dart:math';

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_coroutines/testing.dart';
import 'package:test/test.dart';

/// How many seeded runs the property is checked on.
const _runs = 40;

/// How many producers send in one run.
const _producers = 3;

/// How many elements each producer sends.
const _elementsPerProducer = 10;

/// How many consumers receive in one run; the last two are never
/// cancelled, so every channel is drained.
const _consumers = 4;

/// Receives from [channels] with competing selects until every one of them
/// is closed, adding each element to [received] and waiting [pause]
/// between two receives; [unbiased] picks `selectUnbiased`.
///
/// Returns a future that completes once every channel is closed.
Future<void> _consume(
  List<Channel<int>> channels,
  List<int> received,
  Duration pause, {
  required bool unbiased,
}) async {
  final open = List<Channel<int>>.of(channels);
  while (open.isNotEmpty) {
    void clauses(SelectBuilder<(Channel<int>, ChannelResult<int>)> it) {
      for (final channel in open) {
        it.onReceiveCatching(channel, (result) => (channel, result));
      }
    }

    final (Channel<int> channel, ChannelResult<int> result) = unbiased
        ? await selectUnbiased(clauses)
        : await select(clauses);
    if (result.isClosed) {
      open.remove(channel);
      continue;
    }
    received.add(result.getOrThrow());
    await delay(pause);
  }
}

/// Runs one seeded scenario: producers send through plain sends and
/// competing send selects, consumers receive through competing receive
/// selects, and some of them are cancelled midway - right after an element
/// was offered, so that it may be handed over to a select whose caller is
/// cancelled before it takes it.
///
/// Returns a future that completes once every element sent met its fate.
Future<void> _run(TestScope scope, Random random) async {
  final undelivered = <int>[];
  final channels = <Channel<int>>[
    for (var index = 0; index < 3; index++)
      Channel<int>(
        capacity: random.nextInt(3),
        onUndeliveredElement: undelivered.add,
      ),
  ];
  final sent = <int>[];
  final received = <int>[];
  final producers = <Job>[];
  for (var producer = 0; producer < _producers; producer++) {
    final List<
      ({
        int element,
        Duration pause,
        Channel<int> first,
        Channel<int> second,
        bool plain,
      })
    >
    plan = [
      for (var index = 0; index < _elementsPerProducer; index++)
        (
          element: producer * 100 + index,
          pause: Duration(milliseconds: random.nextInt(30)),
          first: channels[random.nextInt(channels.length)],
          second: channels[random.nextInt(channels.length)],
          plain: random.nextBool(),
        ),
    ];
    producers.add(
      scope.launch((it) async {
        for (final step in plan) {
          await delay(step.pause);
          if (step.plain) {
            await step.first.send(step.element);
            sent.add(step.element);
            continue;
          }
          await select<void>((it) {
            it
              ..onSend(step.first, step.element, (channel) {})
              ..onSend(step.second, step.element, (channel) {});
          });
          sent.add(step.element);
        }
      }),
    );
  }
  final consumers = <Job>[
    for (var consumer = 0; consumer < _consumers; consumer++)
      scope.launch(
        (it) => _consume(
          channels,
          received,
          Duration(milliseconds: random.nextInt(20)),
          unbiased: consumer.isEven,
        ),
      ),
  ];
  for (var consumer = 0; consumer < _consumers - 2; consumer++) {
    final Job victim = consumers[consumer];
    final cancelAt = Duration(milliseconds: random.nextInt(200));
    final Channel<int> target = channels[random.nextInt(channels.length)];
    scope.launch((it) async {
      await delay(cancelAt);
      final int element = 900 + consumer;
      if (target.trySend(element).isSuccess) {
        sent.add(element);
      }
      victim.cancel();
    });
  }
  await producers.joinAll();
  for (final channel in channels) {
    channel.close();
  }
  await consumers.joinAll();
  for (final channel in channels) {
    channel.cancel();
  }

  expect(
    [...received, ...undelivered]..sort(),
    List<int>.of(sent)..sort(),
    reason: 'every element sent is received or reported exactly once',
  );
  expect(
    sent.where((element) => element < 900),
    hasLength(_producers * _elementsPerProducer),
  );
}

/// Covers competing selects: senders racing over several channels and
/// receivers racing for their elements, some cancelled midway, never lose
/// or duplicate an element.
void main() {
  test(
    'competing selects never lose or duplicate an element',
    () => runTest((it) async {
      for (var run = 0; run < _runs; run++) {
        await _run(it, Random(run));
      }
    }),
  );
}
