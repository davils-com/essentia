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

import 'destination_config.dart';
import 'queue_config.dart';
import 'queue_config_builder.dart';

/// Assembles a [DestinationConfig].
final class DestinationConfigBuilder
    extends ValidatingBuilder<DestinationConfig> {
  /// The name of the destination.
  var name = '';

  /// The queue configured so far.
  QueueConfig? _queue;

  /// Makes the destination asynchronous, configured by [block].
  void async(void Function(QueueConfigBuilder it) block) {
    _queue = nested<QueueConfig, QueueConfigBuilder>(
      QueueConfigBuilder(),
      'queue',
      block,
    );
  }

  /// Assembles the destination.
  @override
  DestinationConfig assemble() => DestinationConfig(name, _queue);
}
