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

/// A schema of several flags with long, similar names.
final class ManyFlagParameters extends Parameters {
  /// Creates the schema.
  ManyFlagParameters();

  /// The first numbered flag.
  final Parameter<bool> first = flag(<String>['--parameter-number-0']);

  /// The second numbered flag.
  final Parameter<bool> second = flag(<String>['--parameter-number-1']);

  /// The third numbered flag.
  final Parameter<bool> third = flag(<String>['--parameter-number-2']);

  /// A short flag name.
  final Parameter<bool> mode = flag(<String>['--mode']);

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    first,
    second,
    third,
    mode,
  ];
}
