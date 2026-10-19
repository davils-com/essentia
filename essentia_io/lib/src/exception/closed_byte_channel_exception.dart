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

import 'package:essentia_io/src/exception/io_exception.dart';

/// Thrown when a byte channel is used after it was cancelled; [cause] is
/// what it was cancelled with.
base class ClosedByteChannelException extends IoException {
  /// Creates the exception for a channel cancelled with [cause].
  ClosedByteChannelException([Object? cause, StackTrace? causeStackTrace])
    : super(_messageOf(cause), cause: cause, causeStackTrace: causeStackTrace);

  /// The message that tells what the channel was cancelled with.
  ///
  /// Returns it.
  static String _messageOf(Object? cause) {
    if (cause == null) {
      return 'The channel was closed';
    }
    if (cause is IoException) {
      return cause.message;
    }
    return 'The channel was cancelled';
  }

  /// The name of the exception in its description.
  @override
  String get kind => 'ClosedByteChannelException';
}
