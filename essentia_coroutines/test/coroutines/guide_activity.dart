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

/// The activity of the coroutine context and dispatcher examples, which owns
/// the scope of its coroutines.
final class GuideActivity {
  /// Creates the activity logging into [log].
  GuideActivity(this.log);

  /// What the activity prints.
  final List<String> log;

  /// The scope of the activity.
  final CoroutineScope _scope = mainScope();

  /// Cancels every coroutine of the activity.
  void destroy() => _scope.cancel();

  /// Launches ten coroutines that work for a different time each.
  void doSomething() {
    for (var i = 0; i < 10; i++) {
      _scope.launch((it) async {
        await delay(Duration(milliseconds: (i + 1) * 200));
        log.add('Coroutine $i is done');
      });
    }
  }
}
