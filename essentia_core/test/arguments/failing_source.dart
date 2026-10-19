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

/// A value source that fails for every parameter, as one whose server
/// refused the connection would.
final class FailingSource implements ValueSource {
  /// Creates the source.
  const FailingSource();

  /// `vault`.
  @override
  String get name => 'vault';

  /// Fails.
  @override
  Future<String?> read(ParameterInfo parameter) =>
      Future<String?>.error(Exception('connection refused'));
}
