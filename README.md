# Essentia

Essentia is the Davils application runtime core for Dart - a port of the Kotlin library Arc. It
validates configuration through one model that reports every problem at once, turns the parameters
a program is started with into typed immutable values, carries events between the parts of one
program, and holds the small building blocks the rest is made of: layering contracts, RFC 9562
identifiers, platform detection, a `Result` type and Kotlin's standard library extensions on
Dart's own classes.

Its only runtime dependency is `package:meta`.

Everything is exported from `package:essentia/essentia.dart`: validation, the builder DSL, program
parameters, the event bus, identifiers, semantic versions, principals, layering contracts, platform
detection, scope functions, `Result` and the Kotlin stdlib extensions.

It runs on every Dart platform: the VM and native executables, Flutter, the web and WebAssembly.
The test suite runs on all of them. Where a platform has no `dart:io`, the program parameters read
no process environment, a path with a declared check is refused because it cannot be checked, and
`file()` is not offered, since there is no `File` to convert to.

## Kotlin lambdas, the Dart way

Arc's DSLs are lambdas with a receiver. Dart has no receivers, so every configuration block takes
the object it configures as its parameter, named `it`, and the shape of the code stays the same:

```kotlin
val bus = eventBus(scope) {
    listener = MetricsListener(registry)
    topic(Topics.users) {
        partitions = 4
        requiresKey = true
    }
}
```

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
so `LoggingBuilder().apply(block).build()` reads exactly as it does in Kotlin.

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
- **Stops cleanly.** `drain()` delivers what is in flight; `dispose()` does not wait and says what
  it dropped.

## Semantic versions

`SemanticVersion` and `SemanticVersionRange` follow semver.org 2.0.0. Ranges are read in npm and
Cargo syntax, combine with `intersect` and `union`, and select from a list:

```dart
final SemanticVersion version = SemanticVersion.parse('1.4.0-rc.1');
final range = SemanticVersionRange.parse('^1.2 || >=2.0.0 <2.1.0');

range.contains(version);                       // true, by precedence
range.contains(version, PreReleasePolicy.sameCoreOnly); // false, npm's rule
version.nextMinor();                           // 1.4.0
'1.2.3'.toSemanticVersionOrNull();
```

`parameter(<String>['--min-version']).semanticVersion()` reads one as a program parameter, and
`scope.semanticVersion(text, property: 'version')` validates one inside a `Validatable`.

## Principals

Who is acting: a user, a service or the system, with roles, a tenant, maskable attributes and
delegation that keeps the originator for audit. The current principal travels in a `Zone`, the
way Arc carries it in the coroutine context:

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

## Kotlin's standard library on Dart's classes

The extensions Kotlin has and Dart does not, under the names Kotlin gives them. Every one says in
its documentation which Kotlin function it mirrors, and every collection it returns is unmodifiable.

| On | Extensions |
|---|---|
| `Iterable` | `associate`, `associateWith`, `groupingBy`, `partitionWhere`, `sumOfInt`, `countWhere`, `indexOfFirst`, `maxBy`, `minOf`, `joinToString`, `sortedByDescending`, `toSortedSet`, `random`, `intersect`, `union`, `subtract`, `mapNotNull`, `distinctBy`, `onEach`, `zip`, `windowed`, `zipWithNext`, `runningFold`, `runningReduce`, `requireNoNulls`, `unzip`, `orEmpty`, `isNullOrEmpty` … |
| `List`, `Set` | `lastIndex`, `indices`, `getOrElse`, `foldRight`, `reduceRight`, `removeFirstOrNull`, `takeLast`, `dropLastWhile`, `plusElement`, `minusAll` … |
| `Map` | `getValue`, `getOrElse`, `withDefault`, `mapKeys`, `mapValues`, `minusKey`, `toSortedMap`, `any`, `none`, `countWhere` … |
| `String` | `removePrefix`, `removeSurrounding`, `substringBefore`, `substringAfterLast`, `take`, `dropLast`, `capitalize`, `equalsIgnoreCase`, `isBlank`, `ifBlank`, `trimIndent`, `trimMargin`, `lines`, `windowed`, `chunked`, `splitWithLimit`, `toIsoDuration`, and `words`, `toSnakeCase`, `toKebabCase`, `toCamelCase`, `toPascalCase` spelled as kotlinx serialization's naming strategies spell them, and `closestIn`, the bounded "did you mean" search … |
| `int`, `double`, `Duration` | `5.seconds`, `1.5.hours`, `floorDiv`, `mod`, `rangeTo`, `until`, `downTo`, `toComponents`, `toIsoString`, `duration / duration` |
| `Comparable`, `Comparator` | `coerceIn`, `coerceAtLeast`, `rangeTo`, `rangeUntil`, `thenBy`, `thenByDescending`, with `compareBy`, `naturalOrder` and `nullsLast` beside them |
| `Future`, `Stream` | `timeoutOrNull`, and the `Flow` operators `mapLatest`, `collectLatest`, `flatMapMerge`, `zip`, `onStart`, `onCompletion`, `onEmpty`, `runningReduce`, `distinctUntilChangedBy` … |

`Result` is Kotlin's: `runCatching`, `valueOrNull`, `getOrThrow`, `fold`, `map`, `mapCatching`,
`recover`, `onSuccess`, `onFailure`, with extensions on `Future<Result<T>>` and
`Iterable<Result<T>>`. The ranges `IntRange`, `IntProgression`, `ClosedRange` and `OpenEndRange`
are what `rangeTo`, `until` and `downTo` hand back.

## Also in the box

- **Layering contracts.** `DomainModel`, `DataTransferObject`, `Mapper`, `DataSource`, `Repository`
  and `UseCase`.
- **Identifiers.** `UuidV4` reveals nothing; `UuidV7` sorts by when it was minted and is minted
  monotonically.
- **Platform detection.** `Platform`, `OperatingSystem` and `Architecture`, with
  `Platform.current()` read from the VM's ABI and `null` for a machine Essentia cannot name, and
  `Platform.parse('linux-x86_64')` for an identifier read from a path or a manifest.

## Differences to Arc

Kept deliberately small, and only where Dart has no equivalent:

- No coroutine scopes or dispatchers: topics run on the isolate's event loop.
- No concurrent collections. An isolate shares no memory, so Arc's `CopyOnWriteList`,
  `CopyOnWriteSet`, `CopyOnWriteMap`, `ConcurrentMap` and `LongAdder` are not ported. Where Arc
  uses one internally, Essentia uses the Dart idiom: an unmodifiable list that is replaced on every
  write, and plain `int` counters.
- `ArcDsl`, `ArcExperimental` and `ArcInternal` are not ported; `package:meta`'s `@internal`,
  `@protected` and `@visibleForTesting` take their place.
- Property references become property names: `scope.fail('msg', property: 'sinks')`.
- Violation codes are namespaced `essentia.*` instead of `arc.*`.
- The current principal and the envelope being handled travel in a `Zone` instead of the coroutine
  context. `tryPublish` therefore reads both as well; Arc's `tryPublish` has no context to read.
  `publishAs` and `tryPublishAs` replace Arc's overloads with an explicit principal.
- A converter or a value source is contained when it throws an `Exception`; an `Error` is a
  programming mistake and is not caught.
- Parameters are declared with the top level functions `parameter` and `flag` instead of protected
  methods of the schema: a Dart field initialiser cannot reach `this`, and Essentia uses no `late`.
  The schema registers them as it is constructed, as Arc's delegates do, so a clash of names or
  environment variables is refused by the constructor.
- Dart has no overloading, so where Arc offers two forms there is one with an optional argument:
  `contains(version, [policy])`, `nextPreRelease([label])`, `principal(id, [block])`.
- `long()` is not needed (Dart's `int` is 64-bit), `default` and `enum` are reserved words
  (`defaultsTo`, `enumeration`), and errors that are programming mistakes extend `ArgumentError` or
  `StateError` (`TopicNotDeclaredError`, `ParametersNotLoadedError`).

## Quality gates

Essentia is checked by [Inspectra](https://pub.dev/packages/inspectra) 2.0.0 with every gate it
ships, each at its strictest setting, configured in the `inspectra:` section of `pubspec.yaml`. A
`policy` locks the gates, so neither `INSPECTRA_*` variables nor the command line can weaken them,
no severity may be ignored and there is no baseline. Besides the `strict` style preset, the custom
rule `no_late` of `tool/style` refuses every `late` variable.

```bash
dart run tool/verify.dart
```

runs format, analysis, the strict style rules and the tests; CI then runs

```bash
dart run inspectra check
```

which adds the public API dump in `api/essentia.api`, the dependency policy, the changelog check, the
secret, license, vulnerability and filesystem scans of Trivy 0.75.0 at every severity and the 97 %
coverage gate.

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) before a change and [TESTING.md](TESTING.md) before a test.
Security problems are reported privately as described in [SECURITY.md](SECURITY.md), and everyone
taking part follows the [Code of Conduct](CODE_OF_CONDUCT.md). Third-party software is listed in
[THIRDPARTY.md](THIRDPARTY.md).

## License

Copyright (c) 2026 Davils GmbH. All rights reserved. See [LICENSE](LICENSE).
