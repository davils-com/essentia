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

import 'async_data.dart';

/// One sink of a logging configuration.
@immutable
final class SinkData implements Validatable {
  /// Creates the sink [name], asynchronous when [async] is given.
  const SinkData(this.name, this.async);

  /// The name of the sink.
  final String name;

  /// The asynchronous part, or `null` for a synchronous sink.
  final AsyncData? async;

  /// States what is wrong with the sink.
  @override
  void validate(ValidationScope scope) {
    if (name.trim().isEmpty) {
      scope.fail('must not be blank', property: 'name');
    }
  }
}
