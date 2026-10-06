# Third-Party Software

This document lists the third-party software Essentia uses or integrates with.

---

## Runtime

- [meta](https://pub.dev/packages/meta) - the `@internal`, `@protected` and `@visibleForTesting`
  annotations, licensed under the
  [BSD 3-Clause License](https://github.com/dart-lang/sdk/blob/main/pkg/meta/LICENSE). It is the only
  package a consumer of Essentia resolves.

## Development

- [Inspectra](https://pub.dev/packages/inspectra) - the quality gates and supply-chain scans, licensed
  under the [Apache License 2.0](https://github.com/davils-com/Inspectra/blob/main/LICENSE).
- [analyzer](https://pub.dev/packages/analyzer) - the syntax tree the custom style rules of `tool/style`
  run on, licensed under the
  [BSD 3-Clause License](https://github.com/dart-lang/sdk/blob/main/pkg/analyzer/LICENSE).
- [build_runner](https://pub.dev/packages/build_runner) - runs the Inspectra builders, licensed under the
  [BSD 3-Clause License](https://github.com/dart-lang/build/blob/master/build_runner/LICENSE).
- [test](https://pub.dev/packages/test) - the test runner on the VM, in Chrome and in WebAssembly,
  licensed under the [BSD 3-Clause License](https://github.com/dart-lang/test/blob/master/pkgs/test/LICENSE).
- [Trivy](https://github.com/aquasecurity/trivy) - vulnerability, secret, misconfiguration and license
  scanner, licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
  Inspectra downloads, verifies and runs the unmodified official release.

## Reference

- [Arc](https://gitlab.davils.com/davils/libraries/arc) - the Davils application runtime core for
  Kotlin, of which Essentia is the Dart port.
