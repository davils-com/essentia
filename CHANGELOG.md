# Changelog

All notable changes to this project are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project adheres to
[Semantic Versioning](https://semver.org/).

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
