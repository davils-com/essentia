/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// A processor architecture Essentia can name.
///
/// A closed set, for the same reason the operating systems are one: these
/// identifiers name directories that binaries are already published into.
/// Anything else resolves to `null`.
///
/// Both processor entries are 64-bit, which is not an oversight. A 32-bit
/// build is not something Davils publishes, and resolving `i386` to
/// something would mean handing a loader a directory that does not exist.
enum Architecture {
  /// 64-bit x86, reported as `amd64`, `x64` or `x86_64` depending on who
  /// is asked.
  x64('x86_64'),

  /// 64-bit ARM, reported as `aarch64` or `arm64`.
  aarch64('aarch64'),

  /// WebAssembly, which is not a processor and is the point: a module is
  /// compiled once and the host decides what it runs on.
  wasm('wasm');

  /// Creates the architecture named [identifier].
  const Architecture(this.identifier);

  /// The lowercase name used in a resource path, `x86_64` in
  /// `/native/linux-x86_64/`.
  final String identifier;

  /// Every spelling a runtime uses, mapped to the architecture it means.
  static const _aliases = <String, Architecture>{
    'amd64': x64,
    'x86_64': x64,
    'x86-64': x64,
    'x64': x64,
    'em64t': x64,
    'aarch64': aarch64,
    'aarch_64': aarch64,
    'arm64': aarch64,
    'wasm': wasm,
    'wasm32': wasm,
    'wasm64': wasm,
  };

  /// Resolves the architecture a runtime is describing.
  ///
  /// The value is trimmed and lowercased first. Unlike an operating system
  /// this is matched exactly: `armv7l` and `arm` are 32-bit and must not
  /// select a 64-bit build, which a prefix match on `arm` would do.
  ///
  /// Returns the architecture, or `null` if [osArch] names one Essentia
  /// cannot.
  static Architecture? resolve(String osArch) =>
      _aliases[osArch.trim().toLowerCase()];
}
