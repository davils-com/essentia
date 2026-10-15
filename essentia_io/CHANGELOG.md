# Changelog

All notable changes to this package are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the package adheres to
[Semantic Versioning](https://semver.org/).

## 1.0.0

### Added

- `Buffer`, kotlinx-io's segmented buffer: numbers, bytes, byte strings and text in and out,
  `peekBytes`, `indexOf`, `indexOfBytes`, `discard`, `copy` and moving bytes between buffers without
  copying them.
- `ByteReadChannel`, `ByteWriteChannel` and `ByteChannel`, Ktor's byte channels with back pressure
  and cancellable waits, `ByteReadChannel.fromBytes`, `fromText`, `fromBuffer`, `fromStream` and
  `empty`, and `CountedByteReadChannel` and `CountedByteWriteChannel`.
- `ByteReadChannelOperations` and `ByteWriteChannelOperations`, Ktor's operations on the channels,
  among them `readLine`, `readLineStrict` with `LineEnding`, and `readUntil`.
- `writer` and `reader` on a `CoroutineScope`, with `WriterJob`, `ReaderJob`, `WriterScope`,
  `ReaderScope`, `ChannelJob` and `ChannelJobOperations`, and `toStream` on a reader.
- `IoException`, `EofException`, `ClosedByteChannelException`, `ClosedReadChannelException`,
  `ClosedWriteChannelException`, `ConnectionClosedException`, `TooLongLineException` and
  `ConcurrentIoException`.
