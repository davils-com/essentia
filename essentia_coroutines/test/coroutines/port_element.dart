/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:isolate';

import 'package:essentia_coroutines/essentia_coroutines.dart';

/// An element marked to cross to the worker isolate that cannot be sent,
/// because it holds a port.
final class PortElement
    with AbstractCoroutineContextElement
    implements IsolateTransferable {
  /// Creates the element holding [port].
  const PortElement(this.port);

  /// The key the element is stored under.
  static const key = CoroutineContextKey<PortElement>('Port');

  /// What makes the element unsendable.
  final ReceivePort port;

  /// The key the element is stored under.
  @override
  CoroutineContextKey<PortElement> get contextKey => key;
}
