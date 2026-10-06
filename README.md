# Essentia

Essentia is the Davils application runtime core for Dart - a port of the Kotlin library Arc. It
validates configuration through one model that reports every problem at once, turns the parameters
a program is started with into typed immutable values, carries events between the parts of one
program, and holds the small building blocks the rest is made of: layering contracts, RFC 9562
identifiers and platform detection.

Its only runtime dependency is `package:meta`.

| Library | What it carries | Platforms |
|---|---|---|
| `package:essentia/essentia.dart` | Validation, builder DSL, event bus, identifiers, layering contracts, platform detection, scope functions | VM, Flutter, web |
| `package:essentia/arguments.dart` | Program parameters | Everything with `dart:io` |

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

## Program parameters

Declare what the program accepts, load it once at startup, then read typed values. Dart has no
delegated properties, so a schema lists its parameters once in `declared`; that list is also the
order of the usage listing.

```dart
final class AppParameters extends Parameters {
  AppParameters() : super(environmentPrefix: 'APP');

  late final Parameter<int> port =
      parameter(<String>['--port', '-p']).integer().required();
  late final Parameter<String> dataDir =
      parameter(<String>['--data-dir']).path(mustExist: true).required();
  late final Parameter<String> dbPassword =
      parameter(<String>['--db-password']).sensitive().required();
  late final Parameter<List<String>> tags =
      parameter(<String>['--tag']).multiple();
  late final Parameter<bool> dryRun = flag(<String>['--dry-run']);

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

## Also in the box

- **Layering contracts.** `DomainModel`, `DataTransferObject`, `Mapper`, `DataSource`, `Repository`
  and `UseCase`.
- **Identifiers.** `UuidV4` reveals nothing; `UuidV7` sorts by when it was minted and is minted
  monotonically.
- **Platform detection.** `Platform`, `OperatingSystem` and `Architecture`, with
  `Platform.current()` read from the VM's ABI and `null` for a machine Essentia cannot name.

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
- `long()` is not needed (Dart's `int` is 64-bit), `default` and `enum` are reserved words
  (`defaultsTo`, `enumeration`), and errors that are programming mistakes extend `ArgumentError` or
  `StateError` (`TopicNotDeclaredError`, `ParametersNotLoadedError`).

## Quality gates

Essentia is checked by [Inspectra](https://pub.dev/packages/inspectra) 1.0.0 with every package gate
it ships, configured in the `inspectra:` section of `pubspec.yaml`:

```bash
dart run tool/verify.dart
```

runs format, analysis, the strict style rules and the tests; CI then runs

```bash
dart run inspectra check
```

which adds the public API dump in `api/essentia.api`, the changelog check, the Trivy scans and the
90 % coverage gate.

## License

Copyright (c) 2026 Davils GmbH. All rights reserved. See [LICENSE](LICENSE).
