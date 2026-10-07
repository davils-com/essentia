# Changelog

All notable changes to this project are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project adheres to
[Semantic Versioning](https://semver.org/).

## 2.0.0

Kotlin's `kotlinx-coroutines-core`, ported: structured concurrency on Dart's futures and zones,
channels, `select`, hot flows on Dart's streams, a dispatcher on worker isolates, and a virtual
event loop for tests. Arc's coroutine contracts hold 1:1 where Dart can express them; the README
lists every difference.

### Added

- `CoroutineContext`, `CoroutineContextKey`, `CoroutineContextElement`,
  `AbstractCoroutineContextElement` and `currentCoroutineContext()`: the context travels in one
  `Zone` value. `CoroutineName`, `CoroutineExceptionHandler` and `handleCoroutineException`.
- Kotlin's `Job` contract: new, active, completing, cancelling, cancelled and completed; children;
  a parent completes only after its children; a failing child cancels its parent and siblings.
  `CompletableJob`, `SupervisorJob`, `NonCancellable`, `invokeOnCompletion`, `join`,
  `cancelAndJoin`, `cancelChildren`, `joinAll`, `JobCancellationException`,
  `CompletionHandlerException` and `suppressedExceptionsOf`.
- `CoroutineScope`, `launch`, `async` with every `CoroutineStart`, `Deferred` - a `Future`, so
  `await deferred` is Kotlin's `deferred.await()` -, `CompletableDeferred`, `awaitAll`,
  `asDeferred`, `coroutineScope`, `supervisorScope`, `withContext`, `withTimeout`,
  `withTimeoutOrNull`, `TimeoutCancellationException`, `mainScope()` and `GlobalScope`.
- `suspendCancellableCoroutine` and `CancellableContinuation`, the building block of every
  cancellable wait; `delay`, `yieldNow` (Kotlin's `yield`), `awaitCancellation`, `ensureActive`
  and `isCurrentCancellation`.
- `CoroutineDispatcher` and `Dispatchers.main`, `Dispatchers.unconfined` and
  `Dispatchers.isolate`, a pool of worker isolates with `limitedParallelism`, on the web the event
  loop; `IsolateBodyNotSendableError`.
- `package:essentia/testing.dart`: `runTest`, `TestScope` with `backgroundScope`,
  `StandardTestDispatcher`, `UnconfinedTestDispatcher` and `UncompletedCoroutinesError`.
- `Channel`, `SendChannel`, `ReceiveChannel`, `ChannelResult`, `BufferOverflow`,
  `ClosedSendChannelException`, `ClosedReceiveChannelException`, `produce`, `ProducerScope`,
  `awaitClose`, `receiveAsStream`, `consumeAsStream`, `consumeEach`, `consume` and `produceIn`.
- `select`, `selectUnbiased`, `SelectBuilder` and `SelectClause` with `onAwait`, `onJoin`,
  `onReceive`, `onReceiveCatching`, `onSend`, `onTimeout` and `onFuture`.
- `SharedFlow`, `MutableSharedFlow`, `StateFlow`, `MutableStateFlow`, `FlowCollector`,
  `SharingStarted`, `SharingCommand`, `shareIn`, `stateIn` and `awaitStateIn`.
- The `Flow` operators on `Stream`: `collect`, `launchIn`, `cancellable`, `buffer`, `conflate`,
  `debounce`, `sample`, `combine`, `flatMapLatest`, `flatMapConcat`, `transformLatest`, `onEach`,
  `runningFold`, `scan`, `retry`, `retryWhen`, `catchError`, `firstOrNull` and `singleOrNull`.
- `PrincipalElement`, the principal as an element of the coroutine context.
- `Semaphore.resize`, a mutable `Semaphore.fair` and unfair hand over, and semaphores of zero
  permits.

### Changed

- `TestScheduler` is a virtual event loop: code run inside it - in `runTest` or
  `TestScheduler.run` - has virtual microtasks, `Timer`s and `Future.delayed`, every microtask
  runs before the next timer, and the advance methods run synchronously there. Called from
  outside, they behave as before. `Scheduler.system` reads the virtual time inside it.
- `Scheduler` is an element of the coroutine context; `Scheduler.current` is the one of the
  current context. `Semaphore.tryAcquireWithin` waits on it unless given one.
- The current principal and the envelope being handled travel in the coroutine context.
- The event bus runs on coroutines: every lane is a channel, and the lanes, subscribers and group
  workers of a topic are coroutines under a supervisor of the topic. Waiting for room to publish is
  cancellable.
- `mapLatest`, `collectLatest` and the other operators that switch to the latest element run each
  element in a job of its own, cancelled before the next one starts.
- `flatMapMerge` refuses a concurrency below one with a `RangeError` of its own.

### Removed

- The internal `Mailbox`; the event bus uses `Channel`.
- `runInJob`, `currentJob`, `Job.invokeOnCancellation`, `Job.whenCancelled` and
  `Job.cancellationException`. Migrate as follows:

  | 1.x | 2.0 |
  |---|---|
  | `runInJob(job, body)` | `withContext(job, (it) => body())` or `CoroutineScope(job).launch(...)` |
  | `currentJob()` | `currentCoroutineContext().get(Job.key)` |
  | `job.invokeOnCancellation(handler)` | `job.invokeOnCompletion(handler, onCancelling: true)`, or `suspendCancellableCoroutine` with `invokeOnCancellation` for a wait |
  | `job.whenCancelled` | `invokeOnCompletion(onCancelling: true, ...)` completing a `Completer` |
  | `job.cancellationException` | `job.isCancelled` and `job.getCancellationException()` |
  | `job.isCompleted` (finished without being cancelled) | `job.isCompleted && !job.isCancelled`; `isCompleted` is now true once a job is final, cancelled or not |
  | `Job()` with `complete()` | `CompletableJob()`; a parent now waits for its children |
  | `Semaphore(0)` refused | allowed: it admits nobody until resized |

## 1.3.0

### Added

- `TimeSource`, `TimeMark` and `TestTimeSource`, Kotlin's `TimeSource.WithComparableMarks`,
  `ComparableTimeMark` and `TestTimeSource`, with `TimeSource.monotonic` on a `Stopwatch`.
- `Clock` with `Clock.system`, Kotlin's `kotlin.time.Clock`.
- `Scheduler` with `Scheduler.system`: a component's time source, clock and timers in one place,
  with `delay`, Kotlin's cancellable `delay`.
- `TestScheduler`, Kotlin's `TestCoroutineScheduler`: virtual time moved on with `advanceTimeBy`,
  `runCurrent` and `advanceUntilIdle`, which is its own time source and clock.
- `Job`, `CancellationException`, `runInJob`, `currentJob` and `ensureActive`: Kotlin's cooperative
  cancellation, carried through a `Zone`.
- `Semaphore` and `Mutex`, Kotlin's `kotlinx.coroutines.sync` primitives: fair, cancellable, with
  `tryAcquireWithin` for a bounded wait.

### Changed

- `flatMapMerge` bounds its inner streams with the public `Semaphore`.

## 1.2.0

### Added

- `Lazy`, `lazy` and `lazyOf`, Kotlin's `lazy { }` for a field that cannot be `late`: the
  initializer runs once on the first read, is retried after it throws, and a read from inside it
  is refused with a `StateError`.

## 1.1.0

### Added

- `ValidationReport.of` and a public `ValidationException` constructor, so a library with a
  validation pass of its own - a decoder that reads a whole document - reports in the same shape
  and its failure is caught as a `ValidationException`.
- `Violation.of` for a violation that has nothing to add to the shared shape.
- `DurationParsing`: `toIsoDuration()` and `toIsoDurationOrNull()` read the ISO 8601 form that
  `toIsoString()` renders, Kotlin's `Duration.parseIsoString`.
- `StringWords`: `words()`, `toSnakeCase()`, `toKebabCase()`, `toScreamingSnakeCase()`,
  `toCamelCase()` and `toPascalCase()`. Snake and kebab case follow kotlinx serialization's
  `JsonNamingStrategy` character for character.
- `StringSimilarity.closestIn`, the bounded "did you mean" search the program parameters use.
- `Platform.parse` and `Platform.tryParse` read a platform from its identifier.

## 1.0.0

### Added

- Validation: `Validatable`, `ValidationScope` with `fail`, `warn`, `at`, `each` and `include`,
  `ValidationReport`, `ValidationException`, `Violation`, `ViolationPath`, `ViolationCode` and
  `Severity`, and `validateAs` / `validateOrThrow` for values no builder assembled.
- Builder DSL: `Builder` and `ValidatingBuilder` with `nested`, `collect` and `adopt`, so nested
  blocks report every problem at once.
- Kotlin scope functions for configuration blocks: `apply`, `let`, `takeIf` and `takeUnless`.
- Program parameters: `Parameters` schemas of final fields declared with `parameter` and `flag`
  and registered as the schema is constructed, with flags, required, defaulted and repeatable
  parameters, conversions, validation, environment fallback, value sources, mutually exclusive
  groups, dependencies, deprecation warnings, masking of sensitive values and a usage listing.
- Event bus: `eventBus`, typed `TopicKey`s, partitions with per-key ordering, consumer groups,
  replay, overflow policies, headers, correlation and causation carried through a `Zone`,
  listeners, interceptors, metrics, `drain` and `dispose`.
- Layering contracts: `DomainModel`, `DataTransferObject`, `Mapper`, `DataSource`, `Repository`
  and `UseCase`.
- RFC 9562 identifiers: `UuidV4` and monotonic `UuidV7`.
- Platform detection: `Platform`, `OperatingSystem` and `Architecture`.
- Lifecycle contracts: `Disposable` and `DisposableAsync`.
- Kotlin's standard library extensions on Dart's own classes: `Iterable`, `List`, `Set`, `Map`,
  `String`, `int`, `double`, `Duration`, `Comparable`, `Comparator`, `Future` and the `Flow`
  operators on `Stream`, with the ranges `IntRange`, `IntProgression`, `ClosedRange` and
  `OpenEndRange`, `Grouping`, `JoinFormat`, `MapWithDefault` and the comparison functions.
- `Result` with `Success` and `Failure`, `runCatching` and extensions on futures and iterables of
  results.
- Semantic versions: `SemanticVersion`, `SemanticVersionRange` in npm and Cargo syntax with range
  algebra, `PreReleasePolicy`, `VersionInterval`, `String` extensions, validation helpers and the
  parameter conversions `semanticVersion()` and `semanticVersionRange()`.
- Principals: `Principal` with kind, roles, tenant, display name, maskable attributes and
  delegation, the `principal` builder, `runAsPrincipal`, `currentPrincipal` and
  `requirePrincipal`.
- Event envelopes carry the principal that published them, consumers run as it, and
  `publishAs` / `tryPublishAs` name one explicitly.
- `EventTopic.hasConsumers`, and a warning (`essentia.event.late-default`) for a bus default set
  after a topic was declared.
- `SourceUnavailable`: a value source that throws is reported instead of ending the load.
- `also` beside the scope functions `apply`, `let`, `takeIf` and `takeUnless`.
- Inspectra 2.0.0 as the quality gate, every gate at its strictest setting: format, lint at
  `info`, the strict style preset with the custom rule `no_late`, API dump, the dependency policy,
  the secret, license, vulnerability and filesystem scans of Trivy 0.75.0 at every severity, the
  97 % coverage gate and the changelog check, with no baseline, no ignorable severity and a policy
  that locks the gates against `INSPECTRA_*` variables and the command line.
- No `late` variable anywhere: the event bus holds its tasks in completers, and test fixtures are
  created where they are used.

### Security

- A validation rule's message on a sensitive parameter is no longer rendered;
  `ValidationFailure.detail` keeps it.
- `Uuid.parse` and `ApplicationMode.byValue` no longer quote the rejected input.
- An envelope renders the type of its payload, never its content, and names its principal by id.
- Partitions are chosen by a hash seeded per topic, so keys chosen to collide under
  `String.hashCode` do not all land in one lane.

### Fixed

- A violation path, parameter signature or parameter name wider than its column is followed by one
  space instead of running into the message, annotations or value next to it (ARC-44).
- A converter throwing an exception other than `ConversionException` is reported as a
  `ConversionFailure`.
- A short bundle with an undeclared letter is refused whole.
- `choice`, `path` and `file` check a declared default.
- Two parameters reading one environment variable, or a malformed variable name, are refused.
- `split('')` is refused, and empty pieces are dropped.
- The "did you mean" search is bounded.
- A second load while `loadFrom` waits on a source is refused, and a failed load can be retried.
- A topic refuses replay, buffer capacity and partitions above their ceilings.
- `group()` on a draining or closed topic throws instead of handing back a dead group.
- A listener or an error handler that throws is discarded and no longer counts a delivery as a
  failure, and a consumer keeps running after its error handler threw.
- An envelope offered to a consumer group whose mailbox closed is reported as dropped.
- Two `TopicKey`s are equal only when they also agree on the payload type.
- A publication that will not wait gives up after a fixed number of evictions.
- Essentia runs on every Dart platform again: the VM, Flutter, the web and WebAssembly. Access to
  the process environment and the file system goes through a conditional import, `file()` moved
  to `FileParameterConverters`, which is exported where `dart:io` is, and a path check that cannot
  be made on a platform without a file system is refused instead of passed.
