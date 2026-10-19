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
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:essentia_coroutines/src/shutdown/shutdown_signal.dart';
import 'package:meta/meta.dart';

/// Watches the page being hidden.
///
/// Returns the signals as they arrive; cancelling the subscription stops
/// listening. Outside a page the stream never emits.
@internal
Stream<ShutdownSignal> watchHostSignals() {
  final JSObject? window = globalContext.getProperty<JSObject?>('window'.toJS);
  final controller = StreamController<ShutdownSignal>(sync: true);
  final JSFunction listener = ((JSAny? _) {
    controller.add(ShutdownSignal.pageHide);
  }).toJS;
  controller
    ..onListen = () {
      window?.callMethod<JSAny?>(
        'addEventListener'.toJS,
        'pagehide'.toJS,
        listener,
      );
    }
    ..onCancel = () {
      window?.callMethod<JSAny?>(
        'removeEventListener'.toJS,
        'pagehide'.toJS,
        listener,
      );
      return controller.close();
    };
  return controller.stream;
}

/// Does nothing: a page does not end itself.
@internal
void exitHost(int code) {}
