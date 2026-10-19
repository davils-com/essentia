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

import 'dart:math';
import 'dart:typed_data';

import 'package:essentia_core/src/identity/uuid_codec.dart';
import 'package:meta/meta.dart';

/// Mints the bytes of new identifiers.
///
/// Version 7 identifiers are minted monotonically: the twelve bits after the
/// version digit are a counter that is seeded at random whenever the
/// millisecond moves on and incremented otherwise, as RFC 9562 describes for
/// its dedicated counter method. Identifiers minted in the same millisecond,
/// or after the clock stepped back, therefore still sort in the order they
/// were minted.
@internal
final class UuidMinter {
  /// Creates a minter drawing randomness from [_random] and the time from
  /// [_clock], in milliseconds since the Unix epoch.
  UuidMinter(this._random, this._clock);

  /// The minter every identifier of this isolate is minted by.
  static final shared = UuidMinter(
    Random.secure(),
    () => DateTime.now().millisecondsSinceEpoch,
  );

  /// The highest value of the counter.
  static const _counterLimit = 0xFFF;

  /// The highest value a fresh counter is seeded with, which leaves room
  /// for at least 2048 identifiers in one millisecond before the counter
  /// borrows from the next one.
  static const _seedLimit = 0x7FF;

  /// Where randomness comes from.
  final Random _random;

  /// Where the time comes from.
  final int Function() _clock;

  /// The millisecond the last version 7 identifier was minted in.
  var _lastMillisecond = -1;

  /// The counter of the last version 7 identifier.
  var _counter = 0;

  /// Mints the bytes of a version 4 identifier.
  ///
  /// Returns sixteen bytes, 122 of their bits random.
  Uint8List mintRandom() {
    final Uint8List bytes = _randomBytes();
    bytes[6] = 0x40 + bytes[6] % 16;
    bytes[8] = 0x80 + bytes[8] % 64;
    return bytes;
  }

  /// Mints the bytes of a version 7 identifier for this moment.
  ///
  /// Returns sixteen bytes that sort after every identifier this minter
  /// minted before.
  Uint8List mintTimeOrdered() {
    _advance(_clock());
    final Uint8List bytes = _randomBytes();
    int remaining = _lastMillisecond;
    for (var index = 5; index >= 0; index--) {
      bytes[index] = remaining % 256;
      remaining = remaining ~/ 256;
    }
    bytes[6] = 0x70 + _counter ~/ 256;
    bytes[7] = _counter % 256;
    bytes[8] = 0x80 + bytes[8] % 64;
    return bytes;
  }

  /// Moves the timestamp and the counter on for an identifier minted at
  /// [now].
  void _advance(int now) {
    if (now > _lastMillisecond) {
      _lastMillisecond = now;
      _counter = _random.nextInt(_seedLimit + 1);
      return;
    }
    _counter++;
    if (_counter <= _counterLimit) {
      return;
    }
    _lastMillisecond++;
    _counter = _random.nextInt(_seedLimit + 1);
  }

  /// Draws sixteen random bytes.
  ///
  /// Returns the bytes.
  Uint8List _randomBytes() {
    final bytes = Uint8List(uuidByteLength);
    for (var index = 0; index < uuidByteLength; index++) {
      bytes[index] = _random.nextInt(256);
    }
    return bytes;
  }
}
