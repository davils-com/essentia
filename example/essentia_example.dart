/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:io';

import 'package:essentia/essentia.dart';

import 'example_parameters.dart';
import 'greeting.dart';

/// The topic the greetings are published on.
final greetings = TopicKey<Greeting>('greetings');

/// Reads who to greet from [argv], publishes a greeting per name and prints
/// what the subscriber received.
Future<void> main(List<String> argv) async {
  final parameters = ExampleParameters();
  try {
    parameters.load(argv);
  } on ParameterException catch (failure) {
    stderr.writeln(failure);
    exitCode = 64;
    return;
  }
  final EventBus bus = eventBus((it) {
    it.topic(greetings, (it) => it.partitions = 2);
  });
  bus
      .topic(greetings)
      .subscribe((it) => stdout.writeln('Hello, ${it.payload.name}!'));
  for (var round = 0; round < parameters.times.value; round++) {
    for (final String name in parameters.names.value) {
      await bus.topic(greetings).publish(Greeting(name), key: name);
    }
  }
  await bus.drain();
}
