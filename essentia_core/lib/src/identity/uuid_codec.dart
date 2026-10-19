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

import 'dart:typed_data';

import 'package:essentia_core/src/identity/uuid_version.dart';
import 'package:meta/meta.dart';

/// The length of the text form of an identifier.
const uuidTextLength = 36;

/// How many bytes an identifier is made of.
const uuidByteLength = 16;

/// The positions of the dashes in the text form.
const _dashPositions = <int>[8, 13, 18, 23];

/// The digits of the text form, in the order of their value.
const _hexDigits = '0123456789abcdef';

/// Reads the sixteen bytes of an RFC 9562 identifier out of [text], in
/// either case.
///
/// Returns the bytes, or `null` when [text] is not the 36-character form or
/// does not carry the RFC 9562 variant.
@internal
Uint8List? uuidBytesOf(String text) {
  if (text.length != uuidTextLength) {
    return null;
  }
  final String digits = _digitsOf(text.toLowerCase()) ?? '';
  if (digits.length != uuidByteLength * 2) {
    return null;
  }
  final bytes = Uint8List(uuidByteLength);
  for (var index = 0; index < uuidByteLength; index++) {
    final int high = _hexDigits.indexOf(digits[index * 2]);
    final int low = _hexDigits.indexOf(digits[index * 2 + 1]);
    if (high < 0 || low < 0) {
      return null;
    }
    bytes[index] = high * 16 + low;
  }
  final isRfcVariant = bytes[8] ~/ 64 == 2;
  if (!isRfcVariant) {
    return null;
  }
  return bytes;
}

/// Reads the version digit out of [bytes].
///
/// Returns the version, or `null` for one Essentia does not mint.
@internal
UuidVersion? uuidVersionOf(Uint8List bytes) =>
    UuidVersion.forNumber(bytes[6] ~/ 16);

/// Renders [bytes] in the 36-character lowercase text form.
///
/// Returns the text form.
@internal
String renderUuid(Uint8List bytes) {
  final text = StringBuffer();
  for (var index = 0; index < uuidByteLength; index++) {
    if (index == 4 || index == 6 || index == 8 || index == 10) {
      text.write('-');
    }
    final int byte = bytes[index];
    text
      ..write(_hexDigits[byte ~/ 16])
      ..write(_hexDigits[byte % 16]);
  }
  return text.toString();
}

/// Explains why [text] could not be read as an identifier.
///
/// The message never quotes [text]: an identifier is routinely a session
/// token or a capability link, and a rejected one may be arbitrarily long.
/// It names the length it got, or says that the text is not a well-formed
/// identifier of a version Essentia mints, in under eighty characters.
///
/// Returns the message of the failure.
@internal
String uuidRefusal(String text) {
  if (text.length != uuidTextLength) {
    return 'Not a UUID: ${text.length} characters, not $uuidTextLength';
  }
  return 'Not a well-formed UUID of a version Essentia mints';
}

/// Compares two identifiers by their bytes, read unsigned and most
/// significant first.
///
/// Returns a negative number, zero or a positive number as [left] sorts
/// before, with or after [right].
@internal
int compareUuidBytes(Uint8List left, Uint8List right) {
  for (var index = 0; index < uuidByteLength; index++) {
    final int difference = left[index] - right[index];
    if (difference != 0) {
      return difference;
    }
  }
  return 0;
}

/// Strips the dashes out of the lowercase text form [text].
///
/// Returns the 32 digits, or `null` when a dash is missing or misplaced.
String? _digitsOf(String text) {
  for (final int position in _dashPositions) {
    if (text[position] != '-') {
      return null;
    }
  }
  final String digits = text.replaceAll('-', '');
  if (digits.length != uuidByteLength * 2) {
    return null;
  }
  return digits;
}
