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
