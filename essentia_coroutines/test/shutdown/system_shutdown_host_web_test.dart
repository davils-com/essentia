/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:test/test.dart';

/// Dispatches a `pagehide` event on the window.
void _hidePage() {
  final JSObject window = globalContext.getProperty<JSObject>('window'.toJS);
  final JSFunction event = globalContext.getProperty<JSFunction>('Event'.toJS);
  window.callMethod<JSAny?>(
    'dispatchEvent'.toJS,
    event.callAsConstructor<JSObject>('pagehide'.toJS),
  );
}

/// Covers `ShutdownHost.system` in a browser.
void main() {
  test('reports the page being hidden until cancelled', () async {
    final seen = <ShutdownSignal>[];
    final StreamSubscription<ShutdownSignal> subscription = ShutdownHost.system
        .watch()
        .listen(seen.add);

    _hidePage();
    expect(seen, <ShutdownSignal>[ShutdownSignal.pageHide]);

    await subscription.cancel();
    _hidePage();
    expect(seen, <ShutdownSignal>[ShutdownSignal.pageHide]);
  });

  test('exiting does nothing in a page', () {
    expect(() => ShutdownHost.system.exit(1), returnsNormally);
  });
}
