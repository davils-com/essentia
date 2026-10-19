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

import 'package:essentia_io/src/buffer/buffer.dart';
import 'package:essentia_io/src/channel/byte_read_channel.dart';
import 'package:meta/meta.dart';

/// A channel without bytes that is closed.
@internal
final class EmptyByteReadChannel implements ByteReadChannel {
  /// Creates the channel.
  EmptyByteReadChannel();

  /// Nothing went wrong.
  @override
  Exception? get closedCause => null;

  /// Nothing can be read.
  @override
  bool get isClosedForRead => true;

  /// An empty buffer of its own for every caller, so that nobody's writes
  /// reach another reader.
  @override
  Buffer get readBuffer => Buffer();

  /// Never holds any bytes.
  ///
  /// Returns `false`.
  @override
  Future<bool> awaitContent([int min = 1]) async => false;

  /// Does nothing: the channel is closed already.
  @override
  void cancel([Object? cause]) {}
}
