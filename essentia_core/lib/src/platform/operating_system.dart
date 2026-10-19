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

/// An operating system Essentia can name.
///
/// A closed set, and short on purpose: these are the systems a Davils
/// program is built and shipped for, and the identifiers name directories
/// that binaries are already published into. Adding one is a decision
/// about a layout other people have shipped against, not a detail.
///
/// Anything else resolves to `null` rather than to a constant meaning
/// "unknown". A sentinel would be comparable, which is the problem with it:
/// `platform.operatingSystem == OperatingSystem.linux` reads `false` on an
/// unrecognised system exactly as it does on Windows, and the two are not
/// the same answer. See [resolve].
enum OperatingSystem {
  /// Linux, and anything reporting itself as Linux.
  linux('linux', isUnix: true),

  /// macOS, whichever of its several names the runtime reports.
  macos('macos', isUnix: true),

  /// Windows, any edition.
  windows('windows', isUnix: false),

  /// Android, which is a Linux kernel and is not a Linux machine.
  ///
  /// It is its own constant rather than [linux] for the reason the whole
  /// table exists: [identifier] names a directory a binary was published
  /// into, and an Android build links against bionic where a Linux build
  /// links against glibc.
  android('android', isUnix: true),

  /// iOS and iPadOS, which are a Darwin kernel and are not a Mac.
  ///
  /// It is its own constant rather than [macos] for the reason [android]
  /// is not [linux]: a binary built for iOS links against a different SDK
  /// and is published into a directory of its own.
  ios('ios', isUnix: true),

  /// A browser or another JavaScript host, where the program is a
  /// WebAssembly module.
  web('web', isUnix: false);

  /// Creates the system named [identifier].
  const OperatingSystem(this.identifier, {required this.isUnix});

  /// The lowercase name used in a resource path, `linux` in
  /// `/native/linux-x86_64/`.
  final String identifier;

  /// Whether the system follows Unix conventions: a path separated by `/`,
  /// a `HOME` variable, POSIX file permissions.
  ///
  /// Stated per constant rather than derived as "not Windows", so that
  /// adding a system that is neither has to answer the question.
  final bool isUnix;

  /// Resolves the system a runtime is describing.
  ///
  /// Matched on a **prefix**, because what a runtime reports is a product
  /// name rather than an identifier: `Windows 11` on one machine, `Mac OS X`
  /// on another. A prefix covers all of those and still refuses what it does
  /// not know. Matching a substring instead, asking whether the name
  /// *contains* `bsd`, is the shape this deliberately does not have: an
  /// operating system this cannot name is a fact worth reporting, and
  /// reporting it needs the answer to be absent rather than wrong.
  ///
  /// The value is trimmed and lowercased first.
  ///
  /// Returns the system, or `null` if [osName] names one Essentia cannot.
  static OperatingSystem? resolve(String osName) {
    final String normalized = osName.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    for (final system in <OperatingSystem>[android, ios, linux, windows, web]) {
      if (normalized.startsWith(system.identifier)) {
        return system;
      }
    }
    final bool isIos =
        normalized.startsWith('ipados') || normalized.startsWith('iphone');
    if (isIos) {
      return ios;
    }
    final bool isMac =
        normalized.startsWith('mac') || normalized.startsWith('darwin');
    if (isMac) {
      return macos;
    }
    return null;
  }
}
