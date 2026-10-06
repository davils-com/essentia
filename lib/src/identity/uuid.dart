/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:typed_data';

import 'package:essentia/src/identity/uuid_codec.dart';
import 'package:essentia/src/identity/uuid_minter.dart';
import 'package:essentia/src/identity/uuid_version.dart';
import 'package:meta/meta.dart';

/// A 128-bit identifier, as specified by RFC 9562.
///
/// The hierarchy is sealed and has one member per version Essentia mints:
/// [UuidV4] for an identifier that says nothing about itself, and [UuidV7]
/// for one that carries the moment it was minted. Taking a [Uuid] as a
/// parameter accepts either; taking a [UuidV7] says the ordering matters.
///
/// The value is held as the sixteen bytes it is made of rather than as
/// text. Comparison, equality and hashing work on those bytes, nothing is
/// parsed to answer a question about an identifier, and the 36-character
/// text form is produced only when somebody asks for it through
/// [toString].
///
/// Identifiers are ordered by their bits, read unsigned. For [UuidV7] that
/// is chronological, because the timestamp leads; for [UuidV4] it is an
/// order, and nothing more.
@immutable
sealed class Uuid implements Comparable<Uuid> {
  /// Creates an identifier made of [_bytes].
  const Uuid._(this._bytes);

  /// Reads an identifier back from its text form, whichever version it is.
  ///
  /// Use this where the version is not known in advance and the result is
  /// going to be matched on. Where it is known, [UuidV4.parse] and
  /// [UuidV7.parse] say so in the type.
  ///
  /// Throws a [FormatException] if [text] is not a well-formed RFC 9562
  /// identifier, or is of a version Essentia does not mint.
  factory Uuid.parse(String text) =>
      tryParse(text) ?? (throw FormatException(uuidRefusal(text), text));

  /// The sixteen bytes, most significant first.
  final Uint8List _bytes;

  /// Reads an identifier back from its text form, or reports that it could
  /// not.
  ///
  /// Use this where a malformed value is an expected outcome, such as a
  /// field read from somewhere Essentia does not control.
  ///
  /// Returns the identifier as whichever member of the hierarchy matches
  /// its version, or `null` if [text] is not a well-formed identifier of a
  /// version Essentia mints.
  static Uuid? tryParse(String text) {
    final Uint8List? bytes = uuidBytesOf(text);
    if (bytes == null) {
      return null;
    }
    return switch (uuidVersionOf(bytes)) {
      UuidVersion.random => UuidV4._(bytes),
      UuidVersion.timeOrdered => UuidV7._(bytes),
      null => null,
    };
  }

  /// Which kind of identifier this is.
  UuidVersion get version;

  /// Orders identifiers by their bits, read unsigned.
  ///
  /// Returns a negative number, zero or a positive number as this
  /// identifier sorts before, with or after [other].
  @nonVirtual
  @override
  int compareTo(Uuid other) => compareUuidBytes(_bytes, other._bytes);

  /// Two identifiers are equal when their bits are.
  @nonVirtual
  @override
  bool operator ==(Object other) =>
      other is Uuid && compareUuidBytes(_bytes, other._bytes) == 0;

  /// The hash of the bits.
  @nonVirtual
  @override
  int get hashCode => Object.hashAll(_bytes);

  /// The 36-character lowercase text form.
  @nonVirtual
  @override
  String toString() => renderUuid(_bytes);

  /// Writes the identifier out as sixteen bytes, most significant first.
  ///
  /// The form to store one in where a text column would be more than twice
  /// the size, and the form RFC 9562 defines the bit layout in terms of.
  ///
  /// Returns a new list of sixteen bytes.
  Uint8List toBytes() => Uint8List.fromList(_bytes);
}

/// A random identifier, as specified by RFC 9562 for UUID version 4.
///
/// 122 bits of randomness and six bits saying what it is. It carries no
/// timestamp, no counter and nothing about the machine that minted it,
/// which is exactly the point: where an identifier must not disclose when
/// something was created or how many of them there are, this is the one to
/// use.
///
/// The cost of saying nothing is that two of these sort in an order that
/// means nothing, and that a database index on them is written to at
/// random. Prefer [UuidV7] for anything stored in quantity.
final class UuidV4 extends Uuid {
  /// Creates the identifier made of its bytes.
  const UuidV4._(super._bytes) : super._();

  /// Mints a new random identifier.
  ///
  /// Drawn from a cryptographically secure source, so one of these is not
  /// guessable from another.
  factory UuidV4.random() => UuidV4._(UuidMinter.shared.mintRandom());

  /// Reads a random identifier back from its text form, in either case.
  ///
  /// Throws a [FormatException] if [text] is not a well-formed UUID, or is
  /// of a version other than 4. A version 7 identifier is refused rather
  /// than accepted and stripped of the timestamp that made it worth having.
  factory UuidV4.parse(String text) =>
      tryParse(text) ?? (throw FormatException(uuidRefusal(text), text));

  /// Reads a random identifier back from its text form, or reports that it
  /// could not.
  ///
  /// Returns the identifier, or `null` if [text] is not a well-formed
  /// version 4 UUID.
  static UuidV4? tryParse(String text) {
    final Uuid? parsed = Uuid.tryParse(text);
    if (parsed is UuidV4) {
      return parsed;
    }
    return null;
  }

  /// Always [UuidVersion.random].
  @override
  UuidVersion get version => UuidVersion.random;
}

/// A time-ordered identifier, as specified by RFC 9562 for UUID version 7.
///
/// The leading 48 bits are the millisecond it was minted in, so sorting a
/// set of these sorts them by when they were created. That is why the
/// envelopes of the event bus carry one: a log or a store that keeps events
/// in identifier order keeps them in the order they happened, and a
/// database index on them is appended to rather than written all over.
///
/// Identifiers minted in the same millisecond still order among
/// themselves, because generation is monotonic rather than purely random
/// within the millisecond.
final class UuidV7 extends Uuid {
  /// Creates the identifier made of its bytes.
  const UuidV7._(super._bytes) : super._();

  /// Mints a new identifier for this moment.
  ///
  /// Two calls in the same millisecond produce identifiers that still
  /// order by which came first, so minting several in a tight loop does not
  /// lose the order they were minted in.
  factory UuidV7.random() => UuidV7._(UuidMinter.shared.mintTimeOrdered());

  /// Creates an identifier from what [minter] mints, for tests that need
  /// to control the clock.
  @visibleForTesting
  factory UuidV7.mintedBy(UuidMinter minter) =>
      UuidV7._(minter.mintTimeOrdered());

  /// Reads a time-ordered identifier back from its text form, in either
  /// case.
  ///
  /// Throws a [FormatException] if [text] is not a well-formed UUID, or is
  /// of a version other than 7. A version 4 identifier is refused rather
  /// than accepted and reported as having been minted in 1970.
  factory UuidV7.parse(String text) =>
      tryParse(text) ?? (throw FormatException(uuidRefusal(text), text));

  /// Reads a time-ordered identifier back from its text form, or reports
  /// that it could not.
  ///
  /// Returns the identifier, or `null` if [text] is not a well-formed
  /// version 7 UUID.
  static UuidV7? tryParse(String text) {
    final Uuid? parsed = Uuid.tryParse(text);
    if (parsed is UuidV7) {
      return parsed;
    }
    return null;
  }

  /// Always [UuidVersion.timeOrdered].
  @override
  UuidVersion get version => UuidVersion.timeOrdered;

  /// The millisecond since the Unix epoch this identifier was minted in.
  int get epochMilliseconds {
    var milliseconds = 0;
    for (var index = 0; index < 6; index++) {
      milliseconds = milliseconds * 256 + _bytes[index];
    }
    return milliseconds;
  }

  /// The moment this identifier was minted, to millisecond resolution, in
  /// UTC.
  DateTime get instant =>
      DateTime.fromMillisecondsSinceEpoch(epochMilliseconds, isUtc: true);
}
