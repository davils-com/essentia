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
import 'package:meta/meta.dart';

/// A failure of input or output: a channel that was closed or cancelled,
/// data that ended too soon, a line that is too long.
///
/// It is named `IoException`, not `IOException`, so that it does not clash
/// with the class of `dart:io` in a file that imports both.
base class IoException implements Exception, Causal {
  /// Creates the exception with [message] and the [cause] behind it.
  const IoException(this.message, {this.cause, this.causeStackTrace});

  /// What went wrong.
  final String message;

  /// The failure behind this one, if there is one.
  @override
  final Object? cause;

  /// Where [cause] was thrown, where it is known.
  @override
  final StackTrace? causeStackTrace;

  /// The name of the exception in [toString], which every subtype names
  /// itself by.
  @protected
  String get kind => 'IoException';

  /// Describes the exception by its [kind] and [message].
  ///
  /// Returns the description.
  @override
  String toString() => '$kind: $message';
}
