# Essentia Compression

Compression for [Essentia](https://github.com/davils-com/essentia#readme), the Davils application runtime for Dart: gzip, zlib
streams and raw deflate data with their frames checked, a decoder of Brotli, and the running checks
CRC-32 and Adler-32.

```dart
import 'package:essentia_compression/essentia_compression.dart';
```

Its only runtime dependency is `package:meta`. It runs on every Dart platform, the web and
WebAssembly included.

## gzip and deflate

```dart
final Uint8List body = await gzip(utf8.encode(json));
final Uint8List text = await gunzip(body);

await File('app.log.gz').openWrite().addStream(
  File('app.log').openRead().transform(gzipEncoder()),
);
```

- `gzip`, `gunzip`, `gzipEncoder` and `gzipDecoder`: one gzip member of RFC 1952. Decoding checks
  the header, the CRC-32 and the length of the trailer and refuses data behind the member.
- `deflate`, `inflate`, `deflateEncoder` and `deflateDecoder`: a zlib stream of RFC 1950, what HTTP
  calls the `deflate` content coding, whose header and Adler-32 decoding checks; with `raw`, deflate
  data of RFC 1951 alone, as a zip entry or a WebSocket message compressed by permessage-deflate
  carries it.

Both run on the zlib of `dart:io` where that is, and on the `CompressionStream` of the browser on
the web, which picks its own level and ignores `level`. On a platform with neither, their streams
fail with an `UnsupportedError`.

## Brotli

```dart
final Stream<Uint8List> body = response.transform(brotliDecoder());
final Uint8List bytes = await unbrotli(compressed);
```

`unbrotli` and `brotliDecoder` decode one Brotli stream of RFC 7932, the content coding `br`. The
decoder is written in Dart and runs alike on the VM, on the web and in WebAssembly. It decodes a
stream as its bytes arrive, hands the bytes on in chunks of up to 16 KiB, holds a window of at most
16 MiB, and refuses damaged, cut short and trailing data with a `FormatException`.

The static dictionary of RFC 7932 Appendix A is generated into
`lib/src/brotli/brotli_dictionary_data.dart` from `tool/brotli/dictionary.bin`:

```bash
dart run tool/brotli/generate_dictionary.dart
```

`--check` fails when the generated file is out of date.

## Checks

```dart
Crc32.of(utf8.encode('123456789')); // 0xCBF43926
Adler32.of(ascii.encode('Wikipedia')); // 0x11E60398
```

`Crc32`, the check gzip, zip and PNG store beside their data, and `Adler32`, the check behind a
zlib stream, take bytes chunk by chunk and give the same answer on every platform.

## License

Apache 2.0 - see [LICENSE](LICENSE). The vendored Brotli data carries its own notice in
[THIRDPARTY.md](THIRDPARTY.md).
