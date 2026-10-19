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

/// A schema declaring a parameter it is handed, which is how one parameter
/// ends up listed by two schemas.
final class SharedParameters extends Parameters {
  /// Creates the schema declaring [shared].
  SharedParameters(this.shared);

  /// The parameter handed to the constructor.
  final Parameter<String?> shared;

  /// Only [shared].
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[shared];
}
