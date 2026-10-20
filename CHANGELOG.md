# Changelog

Essentia is a workspace of packages, and every package keeps its own changelog:
[essentia_core](essentia_core/CHANGELOG.md), [essentia_compression](essentia_compression/CHANGELOG.md),
[essentia_time](essentia_time/CHANGELOG.md), [essentia_coroutines](essentia_coroutines/CHANGELOG.md)
and [essentia_io](essentia_io/CHANGELOG.md).

## 1.0.0

The first release of the workspace; every package starts at 1.0.0.

### Added

- [essentia_core](essentia_core/CHANGELOG.md): validation, the builder DSL, program parameters,
  identifiers, semantic versions, principals, layering contracts, platform detection, bytes,
  charsets, decimals, ranges, scope functions, `Result`, `lazy`, linear regular expressions and the
  extensions on Dart's own classes.
- [essentia_compression](essentia_compression/CHANGELOG.md): gzip, deflate and zlib, a Brotli
  decoder, `Crc32` and `Adler32`.
- [essentia_time](essentia_time/CHANGELOG.md): time sources and clocks, instants, dates, times,
  periods, every IANA time zone, the formats of dates and times and the RFC 5545 recurrence rules.
- [essentia_coroutines](essentia_coroutines/CHANGELOG.md): coroutines, channels, `select`, hot
  flows, the stream operators, locks, the event bus, the principal in the coroutine context,
  shutdown hooks and a virtual event loop for tests.
- [essentia_io](essentia_io/CHANGELOG.md): a segmented `Buffer` and byte channels with back
  pressure.
