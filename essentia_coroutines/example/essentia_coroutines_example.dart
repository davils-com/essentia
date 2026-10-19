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

import 'dart:io';

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/essentia_coroutines.dart';

/// Loads two values at once and waits for both.
Future<void> main() async {
  final (String user, int orders) = await coroutineScope((it) async {
    final Deferred<String> user = it.async((it) async {
      await delay(100.milliseconds);
      return 'alice';
    });
    final Deferred<int> orders = it.async((it) async {
      await delay(50.milliseconds);
      return 3;
    });
    return (await user, await orders);
  });
  stdout.writeln('$user has $orders orders');
}
