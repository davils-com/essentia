# Changelog

All notable changes to this package are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the package adheres to
[Semantic Versioning](https://semver.org/).

## 1.0.0

Split out of `essentia` 3.3.0, whose history is in the [workspace changelog](../CHANGELOG.md).

### Added

- `package:essentia_coroutines/essentia_coroutines.dart`: coroutines, channels, `select`, hot
  flows, the stream operators, locks, the event bus and the principal in the coroutine context
  (`runAsPrincipal`, `currentPrincipal`, `requirePrincipal`, `PrincipalElement`,
  `PrincipalMissingException`).
- `package:essentia_coroutines/testing.dart`: `runTest`, `TestScope`, `TestScheduler` and the test
  dispatchers, which `package:essentia/testing.dart` exported before.
- `ShutdownHooks`, `ShutdownHook`, `ShutdownHost` and `ShutdownSignal`: the work a program does
  when its host signals its end - `SIGINT` and `SIGTERM` where `dart:io` is, the page being hidden
  in a browser - in one place for every component, run one after the other, the last added first,
  within a timeout on the `Scheduler`, before the program ends once with the exit code of the
  signal; and `FakeShutdownHost` in `package:essentia_coroutines/testing.dart`.
