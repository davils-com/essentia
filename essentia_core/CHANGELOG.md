# Changelog

All notable changes to this package are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the package adheres to
[Semantic Versioning](https://semver.org/).

## 1.0.0

Split out of `essentia` 3.3.0, whose history is in the [workspace changelog](../CHANGELOG.md).

### Added

- `package:essentia_core/essentia_core.dart`: validation, the builder DSL, program parameters,
  identifiers, semantic versions, principals, layering contracts, platform detection, bytes,
  decimals and rounding modes, ranges, scope functions, `Result`, `lazy`, `Causal` and
  the extensions on Dart's own classes, as `package:essentia/essentia.dart` exported them.
- The `Duration` extensions - `toDuration`, `toIsoDuration`, `toIsoString`, `toReadableString`,
  `5.seconds`, `toComponents` and `duration / duration` - which lived with the time API before.
- `Charset`, `Charsets` and `UnsupportedCharsetException`: UTF-8, US-ASCII, ISO-8859-1,
  windows-1252, UTF-16, UTF-16BE and UTF-16LE as `Encoding`s of `dart:convert`, found by their IANA
  names and aliases; decoding replaces malformed input with U+FFFD, chunk by chunk.
- `Attributes` and `AttributeKey`, typed attributes, and `CaseInsensitiveMap`, a map whose
  keys compare without regard to case.
- `OperatingSystem.ios` and `Platform.isIos`: iOS and iPadOS resolve to their own system, `ios`,
  rather than to nothing, and are Unix but not macOS. `Platform.entries` grows to eighteen
  machines.
- `use` and `useAsync` on a `Disposable` and `useAsync` on a `DisposableAsync`:
  a block that works with a resource and leaves it disposed whichever way it ends, the failure of
  the block winning over a failure of the disposal.
- `LinearRegExp`, `LinearRegExpException` and `LinearRegExpFailure`: regular expressions of
  ECMAScript in its unicode mode matched in time linear in the length of the text, for
  patterns from documents nobody trusts, such as those of JSON Schema. Backreferences and
  lookarounds, which no linear machine can match, and programs of more than `maxInstructions`
  instructions are refused with the offset and the reason, never the pattern.

### Changed

- `ValidatingBuilder.evaluate` is `@protected` instead of `@internal`, so that a builder of
  another package can evaluate the builders nested in it.

### Removed

- gzip, deflate, the Brotli decoder, `Crc32` and `Adler32`; they are part of `essentia_compression`.
- The principal in the coroutine context - `runAsPrincipal`, `currentPrincipal`,
  `requirePrincipal`, `PrincipalElement` - and `PrincipalMissingException`; they are part of
  `essentia_coroutines`.
