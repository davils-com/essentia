/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// What a relayed stream does with the events of its source, created once
/// for every listener.
///
/// `onData` receives every element of the source, `onDone` runs when the
/// source ends and `onCancel` when the listener cancels. Errors of the
/// source are always passed on unchanged.
@internal
typedef RelayHandlers<T> = ({
  void Function(T element) onData,
  void Function() onDone,
  void Function() onCancel,
});
