/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/platform/architecture.dart';
import 'package:essentia_core/src/platform/current_platform_stub.dart'
    if (dart.library.ffi) 'package:essentia_core/src/platform/current_platform_native.dart'
    if (dart.library.js_interop) 'package:essentia_core/src/platform/current_platform_web.dart';
import 'package:essentia_core/src/platform/operating_system.dart';
import 'package:meta/meta.dart';

/// The machine a program is running on, or one it could be built for: an
/// operating system and an architecture.
///
/// ```dart
/// final Platform platform = Platform.current() ?? (throw StateError(
///   'unsupported machine',
/// ));
///
/// if (platform.isWindows) {
///   return useNamedPipe();
/// }
/// return useUnixSocket();
/// ```
///
/// Its [identifier] is the one spelling of a machine that everything else
/// agrees on, so `/native/linux-x86_64/libfoo.so` is read as this type and
/// nothing has to invent its own naming.
///
/// ## Why it is resolved rather than read
///
/// A runtime reports the machine as two strings, and neither is a closed
/// set. [of] takes both strings as parameters rather than reading them,
/// which is what makes the mapping a table that can be tested exhaustively
/// instead of behaviour that depends on the machine a test happens to run
/// on. [current] is the one line of glue that reads the machine.
///
/// ## Why an unknown machine is null
///
/// There is no `unknown` constant. A sentinel is comparable, so a program
/// could not tell "definitely not Linux" from "no idea", and the difference
/// is the one that decides whether it should stop. `null` has to be
/// handled; a sentinel gets carried.
@immutable
final class Platform {
  /// Creates the platform of [operatingSystem] on [architecture].
  const Platform._(this.operatingSystem, this.architecture);

  /// Every machine this table can name: every operating system crossed with
  /// every architecture, eighteen entries.
  ///
  /// It answers *which machines exist as far as Essentia is concerned*. It
  /// is a **cross product**, so it holds pairs nobody builds for,
  /// `windows-wasm` among them. Whether a binary was published for a
  /// machine is the filesystem's answer; this is only the set of names that
  /// answer could be filed under.
  static final entries = List<Platform>.unmodifiable(<Platform>[
    for (final OperatingSystem system in OperatingSystem.values)
      for (final Architecture architecture in Architecture.values)
        Platform._(system, architecture),
  ]);

  /// The [identifier] of every machine in [entries].
  ///
  /// The direct form of the question callers actually have: *is this string
  /// a platform identifier Essentia resolves*.
  static final identifiers = Set<String>.unmodifiable(
    entries.map((platform) => platform.identifier),
  );

  /// The platform this process runs on, read once.
  static final Platform? _current = currentPlatform();

  /// Which operating system.
  final OperatingSystem operatingSystem;

  /// Which processor architecture.
  final Architecture architecture;

  /// Resolves a platform from what a runtime reports about its machine.
  ///
  /// ```dart
  /// Platform.of('Windows 11', 'amd64')?.identifier; // windows-x86_64
  /// Platform.of('Linux', 'armv7l');                  // null, 32-bit
  /// ```
  ///
  /// Returns the platform, or `null` if either value names something
  /// Essentia cannot. A caller that gets `null` is somewhere nothing was
  /// published for, which is a thing to report rather than to guess at.
  static Platform? of(String osName, String osArch) {
    final OperatingSystem? system = OperatingSystem.resolve(osName);
    final Architecture? architecture = Architecture.resolve(osArch);
    if (system == null || architecture == null) {
      return null;
    }
    return Platform._(system, architecture);
  }

  /// Reads a platform from its [identifier], such as `linux-x86_64`, the
  /// way it is written in a path or a manifest.
  ///
  /// ```dart
  /// Platform.parse('macos-aarch64').isMacos; // true
  /// ```
  ///
  /// Unlike [of], which resolves what a runtime reports, this accepts only
  /// the exact spelling of [identifier]: one of [identifiers].
  ///
  /// Returns the platform.
  ///
  /// Throws a [FormatException] if [identifier] is not one of
  /// [identifiers]. The message does not quote it.
  static Platform parse(String identifier) =>
      tryParse(identifier) ??
      (throw const FormatException('not a platform identifier'));

  /// Reads a platform from its [identifier], or answers `null` when it is
  /// not one of [identifiers].
  ///
  /// Returns the platform, or `null`.
  static Platform? tryParse(String identifier) {
    for (final Platform platform in entries) {
      if (platform.identifier == identifier) {
        return platform;
      }
    }
    return null;
  }

  /// The platform this process is running on.
  ///
  /// Read once and held, because a machine does not change under a running
  /// process, which also makes this safe to call from anywhere.
  ///
  /// Returns the current platform, or `null` if this machine is one
  /// Essentia cannot name.
  static Platform? current() => _current;

  /// The one spelling of this machine, `linux-x86_64`.
  ///
  /// Stable, lowercase and safe in a path: it names the directory binaries
  /// for this machine live in, and it is what a report quotes when there
  /// are none.
  String get identifier =>
      '${operatingSystem.identifier}-${architecture.identifier}';

  /// Whether this machine runs Linux.
  bool get isLinux => operatingSystem == OperatingSystem.linux;

  /// Whether this machine runs macOS.
  bool get isMacos => operatingSystem == OperatingSystem.macos;

  /// Whether this machine runs Windows.
  bool get isWindows => operatingSystem == OperatingSystem.windows;

  /// Whether this machine runs Android.
  ///
  /// Note that this is not covered by [isLinux], deliberately; see
  /// [OperatingSystem.android].
  bool get isAndroid => operatingSystem == OperatingSystem.android;

  /// Whether this machine runs iOS or iPadOS.
  ///
  /// Note that this is not covered by [isMacos], deliberately; see
  /// [OperatingSystem.ios].
  bool get isIos => operatingSystem == OperatingSystem.ios;

  /// Whether this program is running in a browser or another JavaScript
  /// host.
  bool get isWeb => operatingSystem == OperatingSystem.web;

  /// Whether this machine follows Unix conventions: a path separated by
  /// `/`, a `HOME` variable, POSIX file permissions.
  ///
  /// This is the predicate most code actually wants. Asking
  /// `isLinux || isMacos` says the same thing today and stops saying it the
  /// moment a third Unix is added.
  bool get isUnix => operatingSystem.isUnix;

  /// Two platforms are equal when their system and architecture are.
  @override
  bool operator ==(Object other) =>
      other is Platform &&
      operatingSystem == other.operatingSystem &&
      architecture == other.architecture;

  /// The hash of the system and the architecture.
  @override
  int get hashCode => Object.hash(operatingSystem, architecture);

  /// The [identifier].
  @override
  String toString() => identifier;
}
