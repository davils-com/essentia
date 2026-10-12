/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:meta/meta.dart';

import 'async_data.dart';

/// One sink of a logging configuration.
@immutable
final class SinkData implements Validatable {
  /// Creates the sink [name], asynchronous when [async] is given.
  const SinkData(this.name, this.async);

  /// The name of the sink.
  final String name;

  /// The asynchronous part, or `null` for a synchronous sink.
  final AsyncData? async;

  /// States what is wrong with the sink.
  @override
  void validate(ValidationScope scope) {
    if (name.trim().isEmpty) {
      scope.fail('must not be blank', property: 'name');
    }
  }
}
