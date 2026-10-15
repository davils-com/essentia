/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_io/src/buffer/buffer.dart';
import 'package:essentia_io/src/channel/byte_read_channel.dart';
import 'package:meta/meta.dart';

/// A channel without bytes that is closed, Ktor's `ByteReadChannel.Empty`.
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
