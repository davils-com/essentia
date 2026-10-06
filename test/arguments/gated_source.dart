/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/essentia.dart';

/// A value source that answers only once it is opened, so that a load can
/// be caught while it waits.
final class GatedSource implements ValueSource {
  /// Creates the source.
  GatedSource();

  /// Completes once the source is opened.
  final _gate = Completer<void>();

  /// `gate`.
  @override
  String get name => 'gate';

  /// Lets every pending read answer.
  void open() {
    _gate.complete();
  }

  /// Answers `1` once the source is opened.
  @override
  Future<String?> read(ParameterInfo parameter) async {
    await _gate.future;
    return '1';
  }
}
