# Essentia

Essentia is the Davils application runtime core for Dart. It
validates configuration through one model that reports every problem at once, turns the parameters
a program is started with into typed immutable values, carries events between the parts of one
program, and holds the small building blocks the rest is made of: layering contracts, RFC 9562
identifiers, platform detection, a `Result` type and extensions on Dart's own classes.

Its only runtime dependency is `package:meta`.

Essentia is a workspace of five packages; the workspace root holds no library of its own:

| Package | Import | What it holds |
|---|---|---|
| `essentia_core` | `package:essentia_core/essentia_core.dart` | Validation, the builder DSL, program parameters, identifiers, semantic versions, principals, layering contracts, platform detection, bytes, charsets, typed attributes, a case insensitive map, decimals, ranges, scope functions, `Result`, `lazy`, `Duration` and the extensions on Dart's own classes |
| `essentia_compression` | `package:essentia_compression/essentia_compression.dart` | gzip, zlib and raw deflate with their frames checked, a Brotli decoder written in Dart, CRC-32 and Adler-32 |
| `essentia_time` | `package:essentia_time/essentia_time.dart`, `package:essentia_time/recurrence.dart` | Time sources, clocks, instants, dates, times, every IANA time zone, date and time formats, RFC 5545 recurrence |
| `essentia_coroutines` | `package:essentia_coroutines/essentia_coroutines.dart` | Coroutines, channels, `select`, hot flows, stream operators, locks, the event bus and principals in the coroutine context |
| `essentia_io` | `package:essentia_io/essentia_io.dart` | Byte input and output: the segmented `Buffer`, byte channels with back pressure, reading lines and numbers, scanning for a delimiter, `writer` and `reader` coroutines, bridges to streams |

Every package keeps its own test support in `lib/testing.dart`: `package:essentia_time/testing.dart`
holds `TestTimeSource`, `package:essentia_coroutines/testing.dart` testing on virtual time with
`runTest`.

It runs on every Dart platform: the VM and native executables, Flutter, the web and WebAssembly.
The test suite runs on all of them. Where a platform has no `dart:io`, the program parameters read
no process environment, a path with a declared check is refused because it cannot be checked, and
`file()` is not offered, since there is no `File` to convert to.

## Configuration blocks

Every configuration block takes the object it configures as its only parameter, named `it`, and a
nested block configures the part it belongs to:

```dart
final EventBus bus = eventBus((it) {
  it.listener = MetricsListener(registry);
  it.topic(users, (it) {
    it.partitions = 4;
    it.requiresKey = true;
  });
});
```

`apply`, `let`, `takeIf` and `takeUnless` are available on every value through `ScopeFunctions`,
so a builder is configured and finished in one expression: `LoggingBuilder().apply(block).build()`.

Essentia uses no `late`. A value that is expensive to make and may never be needed is held in a
`Lazy`, and read through its `value`:

```dart
final Lazy<RegExp> word = lazy(() => RegExp(r'^[a-z]+$'));

bool isWord(String text) => word.value.hasMatch(text);
```

The initializer runs once, on the first read, and is retried when it throws; `lazyOf(value)` wraps
a value that is already known.

`use` on a `Disposable` works with a resource and disposes of it, and `useAsync` does so for a block that returns a future or a
resource that is a `DisposableAsync`: the resource is disposed whichever way the block ends, and the
failure of the block wins over a failure of the disposal.

```dart
final int entries = openArchive(path).use((it) => it.entries.length);
await openQueue().useAsync((it) => it.send(message));
```

## Validation and configuration DSLs

One validation model serves both program arguments and configuration objects. A data class states
its own invariants; its builder cannot produce an instance that breaks them.

```dart
final class LoggingData implements Validatable {
  const LoggingData(this.rootLevel, this.sinks);

  final LogLevel rootLevel;
  final List<SinkData> sinks;

  @override
  void validate(ValidationScope scope) {
    if (sinks.isEmpty) {
      scope.fail('at least one sink must be configured', property: 'sinks');
    }
    if (rootLevel == LogLevel.trace) {
      scope.warn('trace is expensive in production', property: 'rootLevel');
    }
  }
}

final class LoggingBuilder extends ValidatingBuilder<LoggingData> {
  final List<SinkData> _sinks = <SinkData>[];
  LogLevel level = LogLevel.info;

  void console([void Function(ConsoleSinkBuilder it)? block]) {
    collect(_sinks, ConsoleSinkBuilder(), 'sinks', block ?? (_) {});
  }

  @override
  LoggingData assemble() => LoggingData(level, List.unmodifiable(_sinks));
}

LoggingData logging(void Function(LoggingBuilder it) block) =>
    LoggingBuilder().apply(block).build();
```

- **Nested blocks aggregate instead of throwing.** Three problems spread over three levels arrive in
  one report, each under the path that locates it: `sinks[2].async.queueSize`.
- **Stable codes.** `essentia.parameter.missing-required` is what a program matches on and a
  translation is keyed by; the message is for the person reading it.
- **Warnings.** A warning is reported and stops nothing.
- **Values from outside.** `dto.validateAs('workspace')` returns the report, and
  `dto.validateOrThrow('workspace')` throws a `ValidationException` carrying all of it.
- **Reports from other libraries.** A library with a validation pass of its own - a decoder that
  reads a whole document before it answers - builds its findings with `Violation.of` and
  `ValidationReport.of`, and its failure extends `ValidationException`, so one `catch` and one
  rendering serve both.

## Program parameters

Declare what the program accepts, load it once at startup, then read typed values. Each parameter
is a final field initialised with `parameter` or `flag`. Dart has no delegated properties, so a
schema lists its parameters once in `declared` and registers that list as it is constructed; the
list is also the order of the usage listing. A schema that is wrong - a malformed name, a name or
an environment variable used twice, a parameter another schema declares - cannot be constructed.

```dart
final class AppParameters extends Parameters {
  AppParameters() : super(environmentPrefix: 'APP');

  final Parameter<int> port =
      parameter(<String>['--port', '-p']).integer().required();
  final Parameter<String> dataDir =
      parameter(<String>['--data-dir']).path(mustExist: true).required();
  final Parameter<String> dbPassword =
      parameter(<String>['--db-password']).sensitive().required();
  final Parameter<List<String>> tags =
      parameter(<String>['--tag']).multiple();
  final Parameter<bool> dryRun = flag(<String>['--dry-run']);

  @override
  List<Parameter<Object?>> get declared =>
      <Parameter<Object?>>[port, dataDir, dbPassword, tags, dryRun];
}

void main(List<String> argv) {
  final parameters = AppParameters()..load(argv);
  logger.info(parameters.describe());
  startServer(parameters.port.value);
}
```

- **Every problem in one report**, rendered together with the usage listing.
- **Environment fallback.** `--data-dir` falls back to `APP_DATA_DIR`, and a bad value is reported
  under the variable it came from.
- **Secrets stay out of logs.** `.sensitive()` masks a parameter everywhere Essentia renders it.
- **Value sources.** `loadFrom(argv, sources)` consults a `ValueSource` - a secret store, a
  configuration service - for whatever the command line and the environment did not supply.

## Events

An in-process event bus with typed topics, per-key ordering and consumer groups. Declare the topics
once; the declaration is checked as a whole before anything starts running.

```dart
final users = TopicKey<UserEvent>('users');

final EventBus bus = eventBus((it) {
  it.topic(users, (it) {
    it.partitions = 4;
    it.requiresKey = true;
  });
});

bus.topic(users).subscribe((it) => print(it.payload));
bus.topic(users).group('indexer', (it) => index(it.payload));
await bus.topic(users).publish(const UserRegistered('u-42'), key: 'u-42');
```

- **Order, per key.** Envelopes sharing a key are delivered in publish order.
- **Nothing is lost quietly.** Every discarded envelope is reported with the reason, and the default
  overflow policy discards nothing at all.
- **Causation travels with the work.** Publishing from inside a consumer joins the chain being
  handled; the chain is carried by a `Zone`, so it survives every `await` of the handler.
- **On coroutines.** Every lane is a channel and every lane, subscriber and group worker a coroutine
  of its topic; a publisher waiting for room is cancelled with its job.
- **Stops cleanly.** `drain()` delivers what is in flight; `dispose()` does not wait and says what
  it dropped.

## Semantic versions

`SemanticVersion` and `SemanticVersionRange` follow semver.org 2.0.0. Ranges are written with
comparators, `x` wildcards, `~` and `^`, or as intervals such as `[1.2,2)`, joined with `||`; they
combine with `intersect` and `union`, and select from a list:

```dart
final SemanticVersion version = SemanticVersion.parse('1.4.0-rc.1');
final range = SemanticVersionRange.parse('^1.2 || >=2.0.0 <2.1.0');

range.contains(version);                       // true, by precedence
range.contains(version, PreReleasePolicy.sameCoreOnly); // false, no pre-release asked for
version.nextMinor();                           // 1.4.0
'1.2.3'.toSemanticVersionOrNull();
```

`parameter(<String>['--min-version']).semanticVersion()` reads one as a program parameter, and
`scope.semanticVersion(text, property: 'version')` validates one inside a `Validatable`.

## Principals

Who is acting: a user, a service or the system, with roles, a tenant, maskable attributes and
delegation that keeps the originator for audit. The current principal travels in a `Zone`, so it
reaches every `await` of the work done on its behalf:

```dart
final Principal alice = principal('alice', (it) => it.roles(<String>['admin']));

await runAsPrincipal(alice, () async {
  requirePrincipal().hasRole('admin');           // true
  await bus.topic(users).publish(const UserRegistered('u-42'));
});
```

An envelope records the principal that published it, and every consumer handles it as that
principal, so what a consumer publishes in turn carries the same caller on. `publishAs` names one
explicitly.

## Coroutines

Coroutines on Dart's futures and zones: structured concurrency, cancellation,
timeouts, dispatchers and a virtual event loop for tests. The context of a coroutine - its job, its
name, its exception handler, its dispatcher, its scheduler and its principal - travels in one `Zone`
value, so it reaches every `await` of the work.

```dart
final scope = CoroutineScope(SupervisorJob());

final Job polling = scope.launch((it) async {
  while (true) {
    await delay(30.seconds);
    await refresh();
  }
});

final (User user, List<Order> orders) = await coroutineScope((it) async {
  final Deferred<User> user = it.async((it) => loadUser(id));
  final Deferred<List<Order>> orders = it.async((it) => loadOrders(id));
  return (await user, await orders);
});

final Report? report = await withTimeoutOrNull(5.seconds, (it) => build());
await polling.cancelAndJoin();
```

- **Structured.** A coroutine is a child of the job of its scope; a parent completes only once its
  children did, and a failing child cancels its parent and its siblings unless the parent is a
  `SupervisorJob`. `coroutineScope`, `supervisorScope`, `withContext` and `withTimeout` wait for
  everything they started.
- **Cancellable.** A `Future` cannot be interrupted, so cancellation is cooperative:
  `delay`, `yieldNow`, `join`, `await` on a `Deferred`, channels, `select`, `Mutex` and `Semaphore`
  end with a `CancellationException`, and `suspendCancellableCoroutine` makes any wait of one's own
  cancellable.
- **Dispatched.** `Dispatchers.main` is the event loop; `Dispatchers.isolate` runs a body on a pool
  of worker isolates, one per processor, and on the event loop on the web. An element of the context
  marked `IsolateTransferable` crosses to the isolate with the body, as far as it is sendable.
- **Contextual.** `runWithContext(element, body)` lays elements over the current context for a body,
  synchronous or asynchronous, without starting a coroutine; `runAsPrincipal` is built on it.
- **Shut down together.** `ShutdownHooks.process` is where every component adds the work it has to
  do when the host signals the end of the program: `SIGINT` and `SIGTERM` where `dart:io` is, the
  page being hidden in a browser. The hooks run one after the other, the last added first, within
  a timeout on the `Scheduler`, and the program then ends once, with the exit code of the signal;
  `FakeShutdownHost` raises signals in a test.
- **Tested on virtual time.** `runTest` from `package:essentia_coroutines/testing.dart` runs a test body on the
  virtual event loop of a `TestScheduler`: delays, timers and timeouts take no real time, and the
  test fails with every failure of the coroutines it started.

```dart
test('polls every half minute', () => runTest((it) async {
  it.backgroundScope.launch((it) => poll());
  await delay(100.seconds);
  expect(polls, 3);
}));
```

A component that waits, measures or stamps takes a `Scheduler` - a `TimeSource`, a `Clock` and
cancellable timers in one -, defaulting to `Scheduler.system`, which runs on virtual time inside a
test. `Semaphore` and `Mutex` are fair and cancellable; a `Semaphore` can be resized while its
permits are held.

## Channels, select and hot flows

```dart
final ReceiveChannel<int> squares = scope.produce((it) async {
  for (var x = 1; x <= 5; x++) {
    await it.send(x * x);
  }
});
await squares.consumeEach(print);

final String winner = await select((it) {
  it.onReceive(fast, (value) => 'fast: $value');
  it.onReceive(slow, (value) => 'slow: $value');
  it.onTimeout(1.seconds, () => 'none in time');
});

final counter = MutableStateFlow(0);
counter.update((it) => it + 1);
final Job watching = counter.launchIn(scope);
```

- **Channels.** `Channel` with four capacities - rendezvous, buffered, conflated, unlimited -
  and `BufferOverflow`, `trySend`, `receiveCatching`, `close` that still delivers what was sent,
  `cancel` that reports every element it drops to `onUndeliveredElement`, `produce`, and
  and `receiveAsStream` / `consumeAsStream`.
- **select.** Biased and unbiased, over `onAwait`, `onJoin`, `onReceive`, `onReceiveCatching`,
  `onSend`, `onTimeout` and, added for Dart, `onFuture`. A losing clause never consumes an element.
- **Streams are flows.** A hot flow is a Dart `Stream`: `SharedFlow` and `StateFlow` are
  streams, `shareIn`, `stateIn` and `SharingStarted` share any stream, and the operators Dart's
  `Stream` lacks are extensions - `collect`, `launchIn`, `buffer`, `conflate`, `debounce`,
  `sample`, `combine`, `flatMapLatest`, `flatMapConcat`, `transformLatest`, `runningFold`,
  `retry`, `retryWhen`, `catchError`, `cancellable`. On `runTest` their time is virtual.

## Byte channels

```dart
final WriterJob writing = scope.writer((it) async {
  await it.channel.writeString('HTTP/1.1 200 OK\r\n');
  await it.channel.writeInt(42);
});
final String? statusLine = await writing.channel.readLineStrict(limit: 8192);
final int answer = await writing.channel.readInt();
```

- **Buffers.** `Buffer` holds bytes in segments, numbers big- or little-endian,
  text in any `Charset`, moving the bytes of one buffer into another without copying them.
- **Channels.** On a `ByteChannel` a writer flushes to a reader, and a flush waits once a
  mebibyte waits for the reader; every wait is cancellable through the job of its coroutine.
  `ByteReadChannel.fromBytes`, `fromText`, `fromBuffer` and `fromStream`, `toStream`, and the counted
  channels round it off.
- **Operations.** `readInt`, `readBytes`, `readRemaining`, `readLine` and `readLineStrict`
  with LF, CR LF or lenient endings and a limit, `readUntil` a delimiter, `copyTo`, `writeFully`,
  `writeString` and the others; `writer` and `reader` start the coroutine of one side.

## Dates, times and time zones

`LocalDate`, `LocalTime`, `LocalDateTime`, `Instant`, `UtcOffset`,
`YearMonth`, `DayOfWeek` and `Month`, periods and units, and `TimeZone` with every zone of the IANA
time zone database built in, so a zone reads the same on the VM, in Flutter and on the web:

```dart
final berlin = TimeZone.of('Europe/Berlin');
final Instant start = LocalDateTime.of(2026, 3, 28, 9, 0).toInstant(berlin);

start.plus(1, DateTimeUnit.day, timeZone: berlin); // 2026-03-29T07:00:00Z, 23 hours later
start + const Duration(days: 1);                    // 2026-03-29T08:00:00Z, exact time
berlin.offsetInfo(LocalDateTime.of(2026, 3, 29, 2, 30)); // a gap: the clocks skip it
Clock.system.todayIn(berlin);
```

`localDateTimeFormat`, `localDateFormat`, `localTimeFormat` and `localDateTimePattern` build
formats that write every field at its full width;
`DateTimeFormats` holds the common ones:

```dart
start.format(DateTimeFormats.isoInstantUtc);       // 2026-03-28T08:00:00.000Z
start.format(DateTimeFormats.dateTime, berlin);    // 2026-03-28 09:00:00.000
localDateTimePattern("dd.MM.yyyy 'at' HH:mm").format(LocalDateTime.of(2026, 3, 28, 9, 0));
```

A local time the clocks skip moves forward by the length of the gap, and one they pass twice takes
the earlier offset, as RFC 5545 asks; `ZoneResolution` chooses otherwise. Every count is
exact on the web, where integers are doubles. `tool/generate_tzdata.dart` compiles the database in
`essentia_time/IANA/tzdata` into compact data that is decoded per zone on first use.

## Recurrence

`package:essentia_time/recurrence.dart` holds the recurrence of RFC 5545: rules with every `BY`
part and sets of rules, extra dates and exceptions:

```dart
final standup = RecurrenceSet(
  ZonedAnchor(LocalDateTime.of(2026, 10, 5, 9, 30), berlin),
  rules: <RecurrenceRule>[RecurrenceRule.parse('FREQ=WEEKLY;BYDAY=MO,WE')],
);
standup.occurrencesBetween(LocalDateTime.of(2026, 10, 1, 0, 0), LocalDateTime.of(2026, 11, 1, 0, 0));
```

Repetitions are computed on the clock of the anchor and lazily, the anchor counts towards a
`COUNT`, and `truncatedBefore`, `splitAt` and `movedTo` edit "this and following" and whole series.

## Extensions on Dart's classes

Extensions that fill the gaps of Dart's core classes. Every collection they return is
unmodifiable.

| On | Extensions |
|---|---|
| `Iterable` | `associate`, `associateWith`, `groupingBy`, `partitionWhere`, `sumOfInt`, `countWhere`, `indexOfFirst`, `maxBy`, `minOf`, `joinToString`, `sortedByDescending`, `toSortedSet`, `random`, `intersect`, `union`, `subtract`, `mapNotNull`, `distinctBy`, `onEach`, `zip`, `windowed`, `zipWithNext`, `runningFold`, `runningReduce`, `requireNoNulls`, `unzip`, `orEmpty`, `isNullOrEmpty` … |
| `List`, `Set` | `lastIndex`, `indices`, `getOrElse`, `foldRight`, `reduceRight`, `removeFirstOrNull`, `takeLast`, `dropLastWhile`, `plusElement`, `minusAll` … |
| `Map` | `getValue`, `getOrElse`, `withDefault`, `mapKeys`, `mapValues`, `minusKey`, `toSortedMap`, `any`, `none`, `countWhere` … |
| `String` | `removePrefix`, `removeSurrounding`, `substringBefore`, `substringAfterLast`, `take`, `dropLast`, `capitalize`, `equalsIgnoreCase`, `isBlank`, `ifBlank`, `trimIndent`, `trimMargin`, `lines`, `windowed`, `chunked`, `splitWithLimit`, `toIsoDuration`, `toDuration` (`1h 30m` or `PT1H30M`), and `words`, `toSnakeCase`, `toKebabCase`, `toCamelCase`, `toPascalCase`, `closestIn`, the bounded "did you mean" search, and `toNfc`, `toNfd`, `isNfc`, the Unicode normalization forms of Unicode 16.0.0 … |
| `List<int>` | `toHexString`, `contentEquals`, `contentHashCode`, `toByteString`, with `ByteString` and `HexFormat` beside them, and `hexToByteArray`, `hexToByteString`, `encodeToByteString` on `String` |
| `int`, `double`, `Duration` | `5.seconds`, `1.5.hours`, `floorDiv`, `mod`, `rangeTo`, `until`, `downTo`, `toComponents`, `toIsoString`, `toReadableString`, `duration / duration`, and `ByteSize` with `16.mebibytes` and `ByteSize.parse('1.5GiB')` |
| `Comparable`, `Comparator` | `coerceIn`, `coerceAtLeast`, `rangeTo`, `rangeUntil`, `thenBy`, `thenByDescending`, with `compareBy`, `naturalOrder` and `nullsLast` beside them |
| `Future`, `Stream` | `timeoutOrNull`, and the stream operators `mapLatest`, `collectLatest`, `flatMapMerge`, `zip`, `onStart`, `onCompletion`, `onEmpty`, `runningReduce`, `distinctUntilChangedBy` … |

`Result` holds a value or a failure: `runCatching`, `valueOrNull`, `getOrThrow`, `fold`, `map`, `mapCatching`,
`recover`, `onSuccess`, `onFailure`, with extensions on `Future<Result<T>>` and
`Iterable<Result<T>>`. The ranges `IntRange`, `IntProgression`, `ClosedRange` and `OpenEndRange`
are what `rangeTo`, `until` and `downTo` hand back.

## Compression

`package:essentia_compression/essentia_compression.dart`:

- **gzip and deflate.** `gzip`, `gunzip`, `gzipEncoder` and `gzipDecoder`, and `deflate`,
  `inflate`, `deflateEncoder` and `deflateDecoder` for zlib streams and, with `raw`, deflate data
  alone, on the zlib of `dart:io` and on the `CompressionStream` of the browser; decoding checks the
  CRC-32 and the length of a gzip member and the Adler-32 of a zlib stream. Deflate data alone has
  no check: on the VM data cut short decodes to what it held.
- **Brotli.** `unbrotli` and `brotliDecoder` decode a Brotli stream of RFC 7932, HTTP's `br`, as its
  bytes arrive: a decoder written in Dart with the static dictionary of the RFC, alike on the VM, on
  the web and in WebAssembly, that refuses damaged, cut short and trailing data. There is no
  encoder.
- **Checks.** `Crc32` and `Adler32`, the same on every platform.

## Also in the box

- **Layering contracts.** `DomainModel`, `DataTransferObject`, `Mapper`, `DataSource`, `Repository`
  and `UseCase`.
- **Identifiers.** `UuidV4` reveals nothing; `UuidV7` sorts by when it was minted and is minted
  monotonically.
- **Platform detection.** `Platform`, `OperatingSystem` (Linux, macOS, Windows, Android, iOS and the
  web) and `Architecture`, with `Platform.current()` read from the VM's ABI and `null` for a machine Essentia cannot name, and
  `Platform.parse('linux-x86_64')` for an identifier read from a path or a manifest.
- **Charsets.** `Charset` and `Charsets`: UTF-8, US-ASCII, ISO-8859-1, windows-1252 and UTF-16 with
  and without a byte order mark, found by their IANA names and aliases, as `Encoding`s of
  `dart:convert` that decode chunk by chunk and replace what they cannot decode with U+FFFD.
- **Typed attributes.** `Attributes` holds values of any type, each under its `AttributeKey`;
  `CaseInsensitiveMap` is a map whose keys compare without regard to case.
- **Causes.** `Causal`, implemented by every failure of Essentia that wraps another, gives the
  `cause` and, where it is known, its `causeStackTrace`.

## Design notes

- `ShutdownHooks.process` collects the work every component does when the program is asked to end.
  The hooks run one after the other, the last added first, within a timeout, because a server has
  to stop before the logging it writes to flushes.
- `Clock.now()` returns an `Instant`; `toDateTime()` gives Dart's `DateTime`. Instants cover a
  million years either way, so every count stays exact on the web, and `toEpochMilliseconds` is
  clamped to 2^53 - 1. `Instant - Instant` is `difference`, as on `DateTime`, and the unit and
  period arithmetic takes the zone as a named argument.
- `LocalDate.today`, `epochDays`, `isoWeekNumber`, `isoWeekYear`, `startOfWeek`, `plusDays`,
  `plusMonths` and `plusYears` are there for calendars, and `TimeZone.offsetInfo`, `ZoneRules` and
  `ZoneResolution` are public, because a calendar has to show the gaps and overlaps of daylight
  saving time.
- Where a system does not tell its zone by name, as Android, iOS and Windows do not to a program,
  `TimeZone.currentSystemDefault` is the current fixed offset; an application there hands its zone
  in.
- A topic runs its lanes and consumers as coroutines under a supervisor of its own and does not
  take a `CoroutineScope`; a consumer runs as the principal that attached it.
- `select` clauses are calls on the builder, `it.onReceive(channel, ...)`; the clause getters
  `onAwait`, `onJoin`, `onReceive` and `onSend` exist as well. `onFuture` never selects while the
  clauses register, because a future reports in a later microtask, and a future it loses to is only
  no longer listened to.
- `catch` is a reserved word: the stream operator is `catchError`. `awaitStateIn` waits for the first
  value of a shared state, and `firstOrNull` and `singleOrNull` are getters, like `Stream.first`.
- A hot flow listened to inside a coroutine ends with that coroutine's `CancellationException` once
  it is cancelled; prefer `collect` and `launchIn`. `shareIn`, `stateIn`, `retry` and `retryWhen`
  listen to their upstream again, so it has to be re-listenable; a single-subscription stream fails
  visibly.
- An `await` on a future that completed in the root zone, such as the one `StreamSubscription.cancel`
  returns when there is nothing to wait for, resumes outside the virtual event loop. `runTest` lets
  the real loop run before virtual time moves on, so such work never comes late; the synchronous
  advance methods inside a test do not, and the operators of Essentia avoid such futures.
- If `onUndeliveredElement` throws, the operation that dropped the element throws it.
- There are no concurrent collections. An isolate shares no memory, so Essentia uses an
  unmodifiable list that is replaced on every write, and plain `int` counters.
- `package:meta`'s `@internal`, `@protected` and `@visibleForTesting` mark what is not public API.
- Properties are named by strings: `scope.fail('msg', property: 'sinks')`.
- Violation codes are namespaced `essentia.*`.
- The current principal and the envelope being handled travel in a `Zone`, so `tryPublish` reads
  both as well. `publishAs` and `tryPublishAs` publish with an explicit principal.
- A converter or a value source is contained when it throws an `Exception`; an `Error` is a
  programming mistake and is not caught.
- Parameters are declared with the top level functions `parameter` and `flag`: a Dart field
  initialiser cannot reach `this`, and Essentia uses no `late`. The schema registers them as it is
  constructed, so a clash of names or environment variables is refused by the constructor.
- Dart has no overloading, so where two forms are useful there is one with an optional argument:
  `contains(version, [policy])`, `nextPreRelease([label])`, `principal(id, [block])`.
- An isolate runs one thing at a time, so a `Lazy` runs its initializer at most once and needs no
  locking. A read of the value from inside its own initializer throws a `StateError` instead of
  recursing.
- Coroutines are Dart's `async` functions, so cancellation is cooperative at every suspension
  Essentia provides, never inside a plain `await` of a `Future`; `future.asDeferred()` makes such a
  wait cancellable. Code resumed after an `await` goes on in a microtask of its zone, not through
  the dispatcher; a dispatcher only decides where a body starts. A value resumed into code whose job
  was cancelled in the same microtask is handed to `onCancellation` instead, never lost.
- `await` and `yield` are reserved inside asynchronous functions: `Deferred` is a `Future`, so it is
  awaited with `await deferred`, and a coroutine yields with `yieldNow()`. The default start is
  `CoroutineStart.defaultStart`, since `default` is reserved, and `mainScope()` creates the scope of
  the event loop.
- Dart operators cannot be generic: an element of the context is read with `context.get(Job.key)`
  or `context.job`, and an element names its key with `contextKey`. `Job()` returns a
  `CompletableJob` but is typed `Job`; create a `CompletableJob()` to call `complete`.
- There are no threads: `Dispatchers.main` runs on the event loop, and `Dispatchers.isolate` on
  worker isolates. A body sent there must be sendable; only its `CoroutineName`, its
  `PrincipalElement` and the elements marked `IsolateTransferable` cross, and its children are not
  children of the caller. A body that ignores its cancellation for a second has its isolate killed.
- `Scheduler` bundles the delays, the `TimeSource` and the `Clock` of a coroutine, and is an element
  of the coroutine context. `TestScheduler` is the virtual event loop of a test: inside it `Timer`,
  `Future.delayed` and `Scheduler.system` are virtual, `DateTime.now`, `Stopwatch` and
  `TimeSource.monotonic` are not. Driven from outside, its advance methods let the real event loop
  settle between tasks. `TestTimeSource.advance` moves a test time source on, and refuses a negative
  duration.
- `runTest` reports a failure of a coroutine at its end; an error that escapes a plain `Future`
  fails the test at once through the test's own zone. The test dispatchers are classes rather than
  functions.
- Dart's `int` is 64-bit, `default` and `enum` are reserved words (`defaultsTo`, `enumeration`), and
  errors that are programming mistakes extend `ArgumentError` or `StateError`
  (`TopicNotDeclaredError`, `ParametersNotLoadedError`).

## Quality gates

Essentia is checked by [Inspectra](https://pub.dev/packages/inspectra) 2.0.0 with every gate it
ships, each at its strictest setting, configured once in `inspectra.base.yaml`, which every package
extends. A `policy` locks the gates, so neither the packages, `INSPECTRA_*` variables nor the
command line can weaken them, no severity may be ignored and there is no baseline. Besides the
`strict` style preset, Inspectra's built-in rule `no_late` refuses every `late` variable.

```bash
dart run tool/verify.dart
```

runs format, analysis, the strict style rules and the tests of every package; CI then runs

```bash
dart run inspectra -C <package> check
dart run inspectra check
```

which adds the public API dump in `<package>/api/<package>.api`, the dependency policy, the
changelog check, the secret, license, vulnerability and filesystem scans of Trivy 0.75.0 at every
severity and the 97 % coverage gate.

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) before a change and [TESTING.md](TESTING.md) before a test.
Security problems are reported privately as described in [SECURITY.md](SECURITY.md), and everyone
taking part follows the [Code of Conduct](CODE_OF_CONDUCT.md). Third-party software is listed in
[THIRDPARTY.md](THIRDPARTY.md).

## License

Apache 2.0 - see [LICENSE](LICENSE). Third-party software: [THIRDPARTY.md](THIRDPARTY.md).
