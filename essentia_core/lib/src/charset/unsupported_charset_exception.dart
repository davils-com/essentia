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

/// Thrown when a charset is asked for by a name no supported charset has.
///
/// The name usually comes from outside, such as the `charset` parameter of
/// a content type, so it is an [Exception], not an error.
final class UnsupportedCharsetException implements Exception {
  /// Creates the exception for [charsetName].
  const UnsupportedCharsetException(this.charsetName);

  /// The name asked for.
  final String charsetName;

  /// Describes the exception.
  ///
  /// Returns a message that names the charset.
  @override
  String toString() =>
      'UnsupportedCharsetException: the charset "$charsetName" is not '
      'supported';
}
