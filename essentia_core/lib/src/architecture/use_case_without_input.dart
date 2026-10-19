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

import 'package:essentia_core/src/architecture/use_case.dart';

/// Runs a use case that needs no input without passing `null` for it.
extension UseCaseWithoutInput<O> on UseCase<void, O> {
  /// Runs the use case, so that it is called as `report.invoke()` rather
  /// than `report(null)`.
  ///
  /// Returns what the use case produced.
  Future<O> invoke() => call(null);
}
