# Contributing to Essentia

Essentia is the Dart port of Arc, the Davils application runtime core. Other Davils projects depend
on it at startup, on the VM, in Flutter, on the web and in WebAssembly, and its failure report is
the first thing anyone sees of a program that will not start. That shapes what a contribution has
to clear.

## Before you start

- Read [AGENTS.md](AGENTS.md). It carries the code rules, the porting rules and the repository
  layout. A change that breaks a porting rule is a defect, not a design choice.
- Work happens on `develop`; `main` is the release branch.
- Dart SDK `^3.13.5`, resolved with `dart pub get`. Chrome is needed for the web and WebAssembly
  test runs.

## Making a change

```bash
dart run tool/verify.dart
dart run inspectra -C <package> check
dart run inspectra check
```

A change is ready when all of the following hold:

1. **It is formatted and analyses clean.** `dart analyze --fatal-infos` with the strict preset of
   Inspectra. No `// ignore:` comment; the `no_comments` style rule refuses it anyway.
2. **The style check passes.** `dart run inspectra style` with the `strict` preset and the rule
   `no_late` of Inspectra: no `else`, no comments, a `///` comment on every declaration, one type per
   file, the license header, no `default` or `_` case, and no `late`.
3. **It ships with its tests.** `package:test`, one directory per area, hand-written fakes and no
   mocking library. Behaviour changes are not accepted with tests promised as a follow-up. See
   [TESTING.md](TESTING.md).
4. **It runs on every platform.** The suite passes on the VM, in Chrome compiled to JavaScript and
   in Chrome compiled to WebAssembly. Nothing under `lib/` imports `dart:io` or another platform
   library directly.
5. **The API dump is updated** in the same commit when the public surface changed:
   `dart run inspectra -C <package> api dump`.
6. **The changelog says what changed** for anyone who consumes the public API.
7. **`inspectra check` is green.** Format, lint, style, API, the dependency policy, the changelog,
   the Trivy secret, license, vulnerability and filesystem scans and the coverage gate. Never commit
   a credential, not even in a test fixture.
8. **Coverage did not go down.** The bound in `inspectra.base.yaml` only moves up; lowering it needs a
   maintainer and a reason in the commit message. The `policy` of the configuration locks every
   gate, so neither `--set` nor an `INSPECTRA_*` variable gets a change past it.

## What the library guarantees

Three of the rules in [AGENTS.md](AGENTS.md) come up in almost every change, so they are worth
repeating here.

**A pass reports everything, not the first problem.** Resolution keeps going after a parameter has
failed, validation runs every rule, and a nested builder hands its violations upward rather than
throwing. An early `return` or `throw` in a collecting path turns a complete report back into a
one-problem-per-run guessing game, and it will not be accepted.

**`ArgumentError` and `StateError` are for programming mistakes only.** A malformed parameter name,
a duplicate name or a parameter listed by two schemas is refused as the schema is constructed.
Everything a user of the program can get wrong is reported through `ValidationScope` and ends up
in one exception carrying all of it.

**A value marked sensitive never reaches rendered output.** Not in `describe()`, `usage()`, a
`ParameterException`, a `ValidationReport`, an event envelope or a `toString` anywhere on the path.

## Rendered output is tested character for character

`parameter_report_format_test.dart` and `nested_report_format_test.dart` assert the whole rendered
report, not fragments of it. The report is the product. If your change alters it, update the
expected text in the same commit and read the new output before you do. Do not relax an assertion
into `contains` to get green.

## Dependencies

**Essentia has one runtime dependency, `meta`, and that is a property to defend.** Before adding a
dependency, check whether the Dart SDK already covers what you need; if it genuinely does not, say
in the merge request what the alternative was. Development dependencies are limited to `analyzer`
(for the custom style rules), `build_runner`, `inspectra` and `test`. Adding one needs a maintainer's
approval, and the dependency policy in `pubspec.yaml` lists it in `dev_only`.

`pubspec.lock` is not committed, since Essentia is a library; `inspectra check` still requires the
local lockfile to match `pubspec.yaml` and to carry a checksum for every hosted package. Renovate
keeps the constraints current on `develop`. Third-party software is listed in
[THIRDPARTY.md](THIRDPARTY.md).

## Porting from Arc

Arc is the reference. A behaviour that exists in Arc exists here with the same contract, unless
Dart cannot express it, and the README lists every deliberate difference. A change to such a
difference updates that list in the same commit.

## Commit messages

Conventional commits with the area as scope:

```text
feat(event): add consumer group metrics
fix(arguments): refuse a parameter declared by two schemas
test(validation): cover aggregation across two nesting levels
docs: describe the porting rules
```

Never use the em dash; write a plain dash. Do not add an agent name as co-author. Commit or push
only when asked to.

## Reporting a security issue

Do not open a regular issue. Follow [SECURITY.md](SECURITY.md).
