/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
