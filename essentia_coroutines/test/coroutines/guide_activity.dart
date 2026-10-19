/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
