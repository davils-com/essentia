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

import 'dart:async';

import 'package:essentia_core/essentia_core.dart';

/// A value source that answers only once it is opened, so that a load can
/// be caught while it waits.
final class GatedSource implements ValueSource {
  /// Creates the source.
  GatedSource();

  /// Completes once the source is opened.
  final _gate = Completer<void>();

  /// `gate`.
  @override
  String get name => 'gate';

  /// Lets every pending read answer.
  void open() {
    _gate.complete();
  }

  /// Answers `1` once the source is opened.
  @override
  Future<String?> read(ParameterInfo parameter) async {
    await _gate.future;
    return '1';
  }
}
