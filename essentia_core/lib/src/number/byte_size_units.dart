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

import 'package:essentia_core/src/number/byte_size.dart';

/// The units of a [ByteSize], so that `16.mebibytes` reads like
/// `5.seconds` does.
///
/// Each one throws an [AssertionError] in debug mode when the size would be
/// negative or larger than [ByteSize.maxBytes].
extension ByteSizeUnits on int {
  /// This many kibibytes, 1024 bytes each.
  ByteSize get kibibytes => ByteSize(this * 1024);

  /// This many mebibytes, 1024 kibibytes each.
  ByteSize get mebibytes => ByteSize(this * 1024 * 1024);

  /// This many gibibytes, 1024 mebibytes each.
  ByteSize get gibibytes => ByteSize(this * 1024 * 1024 * 1024);

  /// This many tebibytes, 1024 gibibytes each.
  ByteSize get tebibytes => ByteSize(this * 1024 * 1024 * 1024 * 1024);

  /// This many kilobytes, 1000 bytes each.
  ByteSize get kilobytes => ByteSize(this * 1000);

  /// This many megabytes, 1000 kilobytes each.
  ByteSize get megabytes => ByteSize(this * 1000 * 1000);

  /// This many gigabytes, 1000 megabytes each.
  ByteSize get gigabytes => ByteSize(this * 1000 * 1000 * 1000);

  /// This many terabytes, 1000 gigabytes each.
  ByteSize get terabytes => ByteSize(this * 1000 * 1000 * 1000 * 1000);
}
