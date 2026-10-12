/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/essentia_coroutines.dart';

/// A sendable element that is not marked to cross to a worker isolate.
final class LocalElement with AbstractCoroutineContextElement {
  /// Creates the element.
  const LocalElement();

  /// The key the element is stored under.
  static const key = CoroutineContextKey<LocalElement>('Local');

  /// The key the element is stored under.
  @override
  CoroutineContextKey<LocalElement> get contextKey => key;
}
