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

| Path | Purpose |
|---|---|
| `lib/essentia.dart` | The web-safe public API: validation, DSL, program parameters, events, identity, architecture, platform, scope functions, result, the Kotlin stdlib extensions |
| `lib/src/` | Everything else; one directory per area, mirroring Arc's packages |
| `api/essentia.api` | The recorded public API; `dart run inspectra api check` compares against it |
| `test/` | `package:test` tests, one directory per area; `test/support/` holds shared fixtures |
| `CONTRIBUTING.md`, `TESTING.md` | What a change and a test have to clear; this file wins where they disagree |
| `SECURITY.md`, `CODE_OF_CONDUCT.md`, `THIRDPARTY.md` | Reporting vulnerabilities, the Code of Conduct, the third-party software |
| `trivy-secret.yaml` | The rules of the Trivy secret scan, Markdown included |
| `.gitlab/CODEOWNERS` | The paths that need a maintainer's review |
| `tool/` | `verify.dart`, `license_header.txt`, the header template of the style check, and `style/`, the custom style rules (`no_late`) |

## Verify

```bash
dart run tool/verify.dart
```

Runs `dart format --set-exit-if-changed`, `dart analyze --fatal-infos`, `inspectra style` and
`dart test` on the VM, in Chrome compiled to JavaScript and in Chrome compiled to WebAssembly.
Nothing is done until it is green. Then:

```bash
dart run inspectra check
```

runs every gate configured in the `inspectra:` section of `pubspec.yaml`, each at its strictest
setting: format, lint, style, API, the dependency policy, changelog, the Trivy scans and the 97 %
coverage gate. Its `policy` locks the gates; never weaken one, add a baseline or an ignore. After a
deliberate API change, record it with `dart run inspectra api dump`.

## Code rules

Enforced by `dart analyze --fatal-infos` with `package:inspectra/lints/strict.yaml` and by
`inspectra style` with the `strict` preset and the custom rules of `tool/style`, without exceptions
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
- Runtime dependencies are limited to `meta`; development dependencies to `analyzer` (for the custom
  style rules), `build_runner`, `inspectra` and `test`. Adding one needs a maintainer's approval.
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
