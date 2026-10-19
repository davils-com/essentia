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

/// Thrown by a send to a channel that was closed without a cause.
///
/// It is a programming mistake, so it is a [StateError]: a sender that may
/// outlive the channel checks `isClosedForSend` or uses `trySend`.
final class ClosedSendChannelException extends StateError {
  /// Creates the exception with [message].
  ClosedSendChannelException([super.message = 'Channel was closed']);

  /// Renders the message.
  @override
  String toString() => 'ClosedSendChannelException: $message';
}
