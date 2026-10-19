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

import 'package:essentia_coroutines/src/deferred/deferred.dart';
import 'package:essentia_coroutines/src/selects/await_clause.dart';
import 'package:essentia_coroutines/src/selects/select_clause.dart';

/// The select clause of a `Deferred`.
extension DeferredSelectClauses<T> on Deferred<T> {
  /// The select clause that wins with the value once the deferred is complete;
  /// a failed deferred makes the select throw its failure, and a lazily started
  /// one is started.
  SelectClause<T> get onAwait => AwaitClause<T>(this);
}
