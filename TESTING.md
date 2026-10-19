# Testing Essentia

Essentia runs before anything else in a program works, on every Dart platform. Its consumers cannot
see its implementation and cannot be handed a patched build on the afternoon they find a defect.
"Everything is covered" therefore has to mean something the build refuses to merge, not something
a team intends.

[AGENTS.md](AGENTS.md)'s Tests section is the short version and it wins: if the two ever disagree,
this file is the one that gets fixed.

## Test tiers

| Tier | What it proves | Where | Blocks merge |
|---|---|---|---|
| Unit tests | The public API behaves as documented | `<package>/test/<area>/*_test.dart` | yes |
| Golden reports | The rendered report is character for character what it was | `*_format_test.dart` | yes |
| Property tests | An invariant holds over generated input, not only the cases someone had | `*_property_test.dart` | yes |
| README examples | Every example of the README compiles and does what the README says | `essentia_coroutines/test/readme_examples_test.dart` | yes |
| Platform tests | Each platform reports the machine it runs on | `essentia_core/test/platform/` | yes |
| API compatibility | The published surface did not move by accident | `<package>/api/<package>.api` | yes |
| Coverage ratchet | The suite still reaches what it reached | `coverage:` in `inspectra.base.yaml` | yes |

## Every platform

`dart run tool/verify.dart` runs the whole suite three times: on the VM, in Chrome compiled to
JavaScript and in Chrome compiled to WebAssembly. A test belongs to every platform unless it cannot,
and only two things stop it:

- **It needs `dart:io`**, such as the path and file conversions of program parameters. It is marked
  `@TestOn('vm')`.
- **It is about one platform**, such as platform detection. It is marked for that platform.

On the web an integer is a double, exact up to 2^53, and bit operations are 32-bit. A test that
passes on the VM only because of 64-bit integers is a defect in the code under test, not in the
test.

## Rules for a test

- `package:test` only. No mocking library: a fake is hand written, lives next to the tests that use
  it, and goes to `test/support/` of its package once two areas share it.
- No real network, no sleeping for a fixed time, no dependence on the wall clock. Asynchronous code
  is awaited or settled, never raced against a delay.
- No `late`. A fixture is created inside the test that uses it, and what has to be cleaned up is
  registered with `addTearDown` right where it is created.
- A property test seeds its `Random` with a fixed number, so a failure reproduces on every run and
  on every platform.
- A golden test asserts the whole rendered text. If a change alters the report, the expected text
  changes in the same commit, after someone read the new output.
- Every fixed bug gets a regression test that fails without the fix.

## Coverage

`dart run inspectra -C <package> check` collects line coverage of the package's `lib/` on the VM and
fails below the bound in `inspectra.base.yaml`. The bound is a ratchet: it sits just below what the suite reaches and only moves up.
Lowering it needs a maintainer and a reason in the commit message, and the configuration `policy`
keeps it from being lowered on the command line.

Coverage says that a line ran, not that anything checked what it did. It is the weakest of the tiers
above and earns its place only because it cannot slip.
