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
