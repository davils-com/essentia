# Essentia Core

The core of [Essentia](../README.md), the Davils application runtime for Dart: validation that
reports every problem at once, validating configuration builders, program parameters, layering
contracts, RFC 9562 identifiers, semantic versions, principals, platform detection, byte strings
and hexadecimal formats, gzip, deflate, Brotli decoding, CRC-32 and Adler-32, charsets, typed attributes, a case
insensitive map, decimals, ranges, a `Result` type, Kotlin's `lazy`, the
`Duration` extensions and Kotlin's standard library extensions on Dart's own classes.

```dart
import 'package:essentia_core/essentia_core.dart';
```

Its only runtime dependency is `package:meta`. It runs on every Dart platform, the web and
WebAssembly included; `file()` is offered where `dart:io` is.
