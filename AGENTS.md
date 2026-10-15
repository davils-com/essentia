# AGENTS.md

Binding rules for every agent and every person working in this repository. Essentia is the Dart
port of Arc, the Davils application runtime core, and it is held to the standard Inspectra checks.

## How to work here

- Never use the em dash. Use a plain dash "-" instead.
- Never add an agent as co-author to a commit message.
- Prefer quality, simplicity and long term maintainability over development cost.
- Essentia is a library. Every declaration carries a `///` comment, and every behaviour change ships
  with its tests in the same change.
- Keep the Kotlin lambda pattern of Arc: a configuration block is a `void Function(B it)` that
  receives the builder it configures, and a builder is finished by a function taking that block.

## Repository

Essentia is a Dart pub workspace. The root holds no library of its own; each package has its own
`lib/`, `test/`, `api/<package>.api`, `CHANGELOG.md`, `README.md` and `dart_test.yaml`.

| Path | Purpose |
|---|---|
| `essentia_core/` | Validation, DSL, program parameters, identity, versions, principals, bytes, architecture, platform, scope functions, result, lazy, ranges, decimals, `Duration` and the Kotlin stdlib extensions. Depends on `meta` only. `tool/brotli/` holds the vendored Brotli dictionary of google/brotli and `generate_dictionary.dart`, which compiles it into `lib/src/bytes/compression/brotli/brotli_dictionary_data.dart`; `test/fixtures/brotli/` holds its test vectors |
| `essentia_time/` | Time sources, clocks, dates, times, time zones, formats (`essentia_time.dart`), RFC 5545 recurrence (`recurrence.dart`), `TestTimeSource` (`testing.dart`). `IANA/tzdata/` is the vendored time zone database, `tool/generate_tzdata.dart` compiles it into `lib/src/internal/tzdata.dart` |
| `essentia_coroutines/` | Coroutines, channels, select, flows, stream operators, locks, the event bus, principals in the coroutine context (`essentia_coroutines.dart`), testing on virtual time: `runTest`, `TestScope`, `TestScheduler` and the test dispatchers (`testing.dart`). `test/support/` holds the shared fixtures of the event tests |
| `essentia_io/` | Byte input and output ported from ktor-io: `Buffer`, `ByteReadChannel`, `ByteWriteChannel`, `ByteChannel`, the channel operations, the `writer` and `reader` coroutines and the bridges to streams |
| `inspectra.base.yaml` | The gates every package extends. Its `policy` locks them |
| `pubspec.yaml` | The workspace and the workspace policy with its layers: `core`, `time` on `core`, `coroutines` on both, `io` on all three |
| `CONTRIBUTING.md`, `TESTING.md` | What a change and a test have to clear; this file wins where they disagree |
| `SECURITY.md`, `CODE_OF_CONDUCT.md`, `THIRDPARTY.md` | Reporting vulnerabilities, the Code of Conduct, the third-party software |
| `trivy-secret.yaml` | The rules of the Trivy secret scan, Markdown included |
| `trivy.yaml`, `.trivyignore.yaml` | Point Trivy at the one accepted notice: the MIT text of google/brotli in `THIRDPARTY.md`, and nothing else |
| `.gitlab/CODEOWNERS` | The paths that need a maintainer's review |
| `tool/` | `verify.dart` and `license_header.txt`, the header template of the style check |

Every package keeps its test support in its own `lib/testing.dart`; a package without test support
has none. Locales, authorization and iCalendar live in Noria (`noria_locale`, `noria_authorization`,
`noria_icalendar`).

## Verify

```bash
dart run tool/verify.dart
```

Runs `dart format --set-exit-if-changed`, `dart analyze --fatal-infos`, `inspectra style` of the
root and of every package, the check that the time zone data is current, and `dart test` of every
package on the VM, in Chrome compiled to JavaScript and in Chrome compiled to WebAssembly. Nothing
is done until it is green. Then:

```bash
dart run inspectra -C <package> check
dart run inspectra check
```

runs every gate of `inspectra.base.yaml` in a package, each at its strictest setting: format, lint,
style, API, the dependency policy, changelog, the Trivy scans and the 97 % coverage gate; at the
root, the workspace policy and the scans of the files outside the packages. Its `policy` locks the
gates; never weaken one, add a baseline or an ignore. After a deliberate API change, record it with
`dart run inspectra -C <package> api dump`.

## Code rules

Enforced by `dart analyze --fatal-infos` with `package:inspectra/lints/strict.yaml` and by
`inspectra style` with the `strict` preset and Inspectra's rule `no_late`, without exceptions
or ignore comments.

- No `else`. Return early. A `switch` over an enum or sealed type is exhaustive and has neither
  `default` nor a wildcard `_` case.
- No comments: no `//`, no `/* */`. The license header is the only exception.
- A `///` documentation comment on every declaration, including private ones.
- No `late`, anywhere: initialise a field where it is declared or in the initialiser list, hand a
  task started in a constructor out through a `Completer`, and create a test fixture inside the
  test with `addTearDown` instead of a `late` variable filled by `setUp`.
- Every file starts with the license header of `tool/license_header.txt`.
- One top level type per file, named after it in snake case. A sealed class and its direct subtypes
  share one file. A file of functions is named after its role.
- `strict-casts`, `strict-inference` and `strict-raw-types` are on. No `dynamic` calls.
- Runtime dependencies are limited to `meta` and the packages of the workspace below a package's
  layer; development dependencies to `inspectra` and `test`. Adding one needs a maintainer's
  approval.
- Essentia runs on every Dart platform: the VM, Flutter, the web and WebAssembly. Nothing under
  `lib/` imports `dart:io`, `dart:ffi` or another platform library directly; host access goes
  through a conditional import (`host_system.dart`, `current_platform*.dart`), and a test that
  needs `dart:io` is marked `@TestOn('vm')`. On the web an integer is a double, exact up to 2^53,
  and bit operations are 32-bit: write `0x100000000`, never `1 << 32`.

## Porting rules

- Arc is the reference. A behaviour that exists in Arc exists here with the same contract, unless
  Dart cannot express it; the README lists every deliberate difference.
- Validation never throws at the first mistake: rules report through `ValidationScope` and return.
- A value marked sensitive never reaches rendered output.
- Programming mistakes are `ArgumentError` or `StateError`; expected failures are `Exception`s
  carrying everything that was found.

## Tests

`package:test` only, no mocking library, no real network. Every fixed bug gets a regression test.

## Git

Conventional commits with the area as scope (`feat(event): ...`, `fix(arguments): ...`). Commit only
when asked.
