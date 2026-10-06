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
| `lib/essentia.dart` | The web-safe public API: validation, DSL, events, identity, architecture, platform, scope functions |
| `lib/arguments.dart` | Program parameters, which need `dart:io` |
| `lib/src/` | Everything else; one directory per area, mirroring Arc's packages |
| `api/essentia.api` | The recorded public API; `dart run inspectra api check` compares against it |
| `test/` | `package:test` tests, one directory per area; `test/support/` holds shared fixtures |
| `tool/` | `verify.dart` and `license_header.txt`, the header template of the style check |

## Verify

```bash
dart run tool/verify.dart
```

Runs `dart format --set-exit-if-changed`, `dart analyze --fatal-infos`, `inspectra style` and
`dart test`. Nothing is done until it is green. Then:

```bash
dart run inspectra check
```

runs every gate configured in the `inspectra:` section of `pubspec.yaml`: format, lint, style, API,
changelog, the Trivy scans and the 90 % coverage gate. After a deliberate API change, record it with
`dart run inspectra api dump`.

## Code rules

Enforced by `dart analyze --fatal-infos` with `package:inspectra/lints/strict.yaml` and by
`inspectra style` with the `strict` preset, without exceptions or ignore comments.

- No `else`. Return early. A `switch` over an enum or sealed type is exhaustive and has neither
  `default` nor a wildcard `_` case.
- No comments: no `//`, no `/* */`. The license header is the only exception.
- A `///` documentation comment on every declaration, including private ones.
- Every file starts with the license header of `tool/license_header.txt`.
- One top level type per file, named after it in snake case. A sealed class and its direct subtypes
  share one file. A file of functions is named after its role.
- `strict-casts`, `strict-inference` and `strict-raw-types` are on. No `dynamic` calls.
- Runtime dependencies are limited to `meta`. Adding one needs a maintainer's approval.

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
