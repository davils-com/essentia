/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/essentia_coroutines.dart';

/// A sendable element marked to cross to the worker isolate.
final class TenantElement
    with AbstractCoroutineContextElement
    implements IsolateTransferable {
  /// Creates the element of [tenant].
  const TenantElement(this.tenant);

  /// The key the tenant is stored under.
  static const key = CoroutineContextKey<TenantElement>('Tenant');

  /// The tenant.
  final String tenant;

  /// The key the tenant is stored under.
  @override
  CoroutineContextKey<TenantElement> get contextKey => key;
}
