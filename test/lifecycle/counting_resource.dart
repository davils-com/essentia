/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

/// A [Disposable] that counts how often it really let go.
final class CountingResource implements Disposable {
  /// How often the release actually ran.
  var _disposals = 0;

  /// Whether the resource was released.
  var _released = false;

  /// How often the release actually ran.
  int get disposals => _disposals;

  /// Whether the resource was released.
  bool get released => _released;

  /// Releases the resource once, ignoring every later call.
  @override
  void dispose() {
    if (_released) {
      return;
    }
    _released = true;
    _disposals++;
  }
}
