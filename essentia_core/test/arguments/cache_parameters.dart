/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

/// A schema declaring both `--cache` and `--no-cache` as flags of their own.
final class CacheParameters extends Parameters {
  /// Creates the schema, listing `--no-cache` first when [_noCacheFirst],
  /// and making `--cache` negatable when [negatableCache].
  CacheParameters({required this._noCacheFirst, bool negatableCache = false})
    : cache = negatableCache
          ? flag(<String>['--cache']).negatable()
          : flag(<String>['--cache']);

  /// Whether `--no-cache` is listed before `--cache`.
  final bool _noCacheFirst;

  /// The flag `--cache`.
  final Parameter<bool> cache;

  /// The flag `--no-cache`.
  final Parameter<bool> noCache = flag(<String>['--no-cache']);

  /// Both flags, in the order chosen at construction.
  @override
  List<Parameter<Object?>> get declared => _noCacheFirst
      ? <Parameter<Object?>>[noCache, cache]
      : <Parameter<Object?>>[cache, noCache];
}
