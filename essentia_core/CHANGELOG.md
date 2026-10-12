# Changelog

All notable changes to this package are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the package adheres to
[Semantic Versioning](https://semver.org/).

## 1.0.0

Split out of `essentia` 3.3.0, whose history is in the [workspace changelog](../CHANGELOG.md).

### Added

- `package:essentia_core/essentia_core.dart`: validation, the builder DSL, program parameters,
  identifiers, semantic versions, principals, layering contracts, platform detection, bytes, gzip
  and CRC-32, decimals and rounding modes, ranges, scope functions, `Result`, `lazy`, `Causal` and
  the Kotlin stdlib extensions, as `package:essentia/essentia.dart` exported them.
- The `Duration` extensions - `toDuration`, `toIsoDuration`, `toIsoString`, `toReadableString`,
  `5.seconds`, `toComponents` and `duration / duration` - which lived with the time API before.

- `OperatingSystem.ios` and `Platform.isIos`: iOS and iPadOS resolve to their own system, `ios`,
  rather than to nothing, and are Unix but not macOS. `Platform.entries` grows to eighteen
  machines.

### Changed

- `ValidatingBuilder.evaluate` is `@protected` instead of `@internal`, so that a builder of
  another package can evaluate the builders nested in it.

### Removed

- The principal in the coroutine context - `runAsPrincipal`, `currentPrincipal`,
  `requirePrincipal`, `PrincipalElement` - and `PrincipalMissingException`; they are part of
  `essentia_coroutines`.
