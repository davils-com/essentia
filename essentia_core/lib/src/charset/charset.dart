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

import 'dart:convert';

import 'package:essentia_core/src/charset/charsets.dart';
import 'package:essentia_core/src/charset/unsupported_charset_exception.dart';

/// A character set: how text becomes bytes and bytes become text.
///
/// A charset is a Dart [Encoding], so it encodes and decodes whole values
/// and transforms streams chunk by chunk. Its [name] and [aliases] are
/// those of the IANA registry: `ISO-8859-1` is Latin-1 and
/// `US-ASCII` is ASCII, not the windows-1252 the WHATWG encoding standard
/// of browsers maps them to.
///
/// Decoding never fails: a byte sequence the charset does not define
/// becomes U+FFFD, the replacement character, as in the browser.
/// Encoding fails with an [ArgumentError] for a character the charset
/// cannot represent, as the encoders of `dart:convert` do.
///
/// ```dart
/// final Charset charset = Charset.forName('latin1');
/// final List<int> bytes = charset.encode('café');
/// final String text = await bytes.transform(charset.decoder).join();
/// ```
abstract base class Charset extends Encoding {
  /// Creates the charset [name], also known as [aliases].
  const Charset(this.name, this.aliases);

  /// The name of the charset in the IANA registry, such as `UTF-8`.
  @override
  final String name;

  /// The other names of the charset, such as `utf8` and `latin1`.
  final List<String> aliases;

  /// Every charset Essentia supports.
  static const available = <Charset>[
    Charsets.utf8,
    Charsets.usAscii,
    Charsets.iso88591,
    Charsets.windows1252,
    Charsets.utf16,
    Charsets.utf16be,
    Charsets.utf16le,
  ];

  /// The charset of [name], one of its names or aliases in any case, with
  /// surrounding white space ignored.
  ///
  /// Returns the charset.
  ///
  /// Throws an [UnsupportedCharsetException] when no supported charset has
  /// that name.
  static Charset forName(String name) {
    final Charset? charset = tryForName(name);
    if (charset == null) {
      throw UnsupportedCharsetException(name);
    }
    return charset;
  }

  /// The charset of [name], as [forName] finds it.
  ///
  /// Returns the charset, or `null` when no supported charset has that
  /// name.
  static Charset? tryForName(String name) {
    final String wanted = name.trim().toLowerCase();
    for (final Charset charset in available) {
      if (charset.name.toLowerCase() == wanted ||
          charset.aliases.any((alias) => alias.toLowerCase() == wanted)) {
        return charset;
      }
    }
    return null;
  }

  /// Whether a supported charset has the name [name].
  ///
  /// Returns `true` when [forName] finds one.
  static bool isSupported(String name) => tryForName(name) != null;

  /// Describes the charset by its name.
  ///
  /// Returns [name].
  @override
  String toString() => name;
}
