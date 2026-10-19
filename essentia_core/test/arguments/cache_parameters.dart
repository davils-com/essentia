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
