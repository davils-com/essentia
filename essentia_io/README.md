# Essentia IO

Byte input and output for [Essentia](../README.md) on the coroutines of `essentia_coroutines`.

```dart
import 'package:essentia_io/essentia_io.dart';
```

- `Buffer`: bytes in segments of 8 KiB, written at the end and read from the front, numbers big- or
  little-endian, text in any `Charset`, searching, and moving the bytes of one buffer into another
  without copying them.
- `ByteReadChannel`, `ByteWriteChannel` and `ByteChannel`: a writer flushes bytes to a reader, a
  flush waits once a mebibyte waits for the reader, and every wait is cancellable through the job
  of its coroutine. A channel has one reader and one writer at a time; a second one fails with a
  `ConcurrentIoException`.
- The operations of `ByteReadChannelOperations` and `ByteWriteChannelOperations`: numbers, exact and
  available bytes, `readRemaining`, `readLine`, `readLineStrict` with a limit, `readUntil` a
  delimiter, `peek`, `skipIfFound`, `discard`, `copyTo`, `writeFully`, `writeString` and more.
- `writer` and `reader` on a `CoroutineScope`, the counted channels, and `ByteReadChannel.fromStream`
  and `toStream` to and from Dart's streams.

It runs on every Dart platform, the web and WebAssembly included.

## Design

- A coroutine body takes its scope as `it`, `readRemaining([max])` reads everything that is left or
  at most `max` bytes, `writePacket` takes a `Buffer`, and the counted channels are
  `asCountedReadChannel()` on a reader and `asCountedWriteChannel()` on a writer, since
  `ByteChannel` is both.
- A byte reads as 0 to 255, as Dart's `Uint8List` holds it; the wider numbers are signed. On the web
  compiled to JavaScript a 64-bit number beyond 2^53 is refused rather than rounded.
- The exceptions are named `IoException` and `EofException`, so that they do not clash with
  `dart:io`.
- `cancel()` without a cause cancels with an `IoException` saying so; a cancelled channel drops the
  bytes it held.
- `readUntil` flushes what it copied before it returns.
- Everything runs on Dart's single thread, so no two coroutines touch a channel at the same moment;
  the one misuse that remains, a second reader or writer, fails with a `ConcurrentIoException`.

## Quality gates

```bash
dart run inspectra -C essentia_io check
```

## License

Copyright (c) 2026 Davils GmbH. All rights reserved. See [LICENSE](../LICENSE).
