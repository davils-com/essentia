/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

/// What handles a consumer that threw: the error and where it was thrown.
typedef EventErrorHandler = FutureOr<void> Function(
  Object error,
  StackTrace stackTrace,
);
