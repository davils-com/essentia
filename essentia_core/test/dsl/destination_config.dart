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
import 'package:meta/meta.dart';

import 'queue_config.dart';

/// One destination of a pipeline.
@immutable
final class DestinationConfig implements Validatable {
  /// Creates the destination [name], queued when [queue] is given.
  const DestinationConfig(this.name, this.queue);

  /// The name of the destination.
  final String name;

  /// The queue, or `null` for a synchronous destination.
  final QueueConfig? queue;

  /// States what is wrong with the destination.
  @override
  void validate(ValidationScope scope) {
    if (name.trim().isEmpty) {
      scope.fail('is required but was not set', property: 'name');
    }
  }
}
