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

/// A schema of two short flags and a short parameter taking a value, for
/// reading bundles.
final class BundleParameters extends Parameters {
  /// Creates the schema, treating unknown arguments by [policy].
  BundleParameters([
    UnknownArgumentPolicy policy = UnknownArgumentPolicy.reject,
  ]) : super(unknownArguments: policy);

  /// A short flag.
  final Parameter<bool> all = flag(<String>['-a']);

  /// Another short flag.
  final Parameter<bool> colour = flag(<String>['-c']);

  /// A short parameter taking an integer.
  final Parameter<int?> port = parameter(<String>['-p']).integer();

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    all,
    colour,
    port,
  ];
}
