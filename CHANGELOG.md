# Changelog

All notable changes to this project are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project adheres to
[Semantic Versioning](https://semver.org/).

## 1.0.0

### Added

- Validation: `Validatable`, `ValidationScope` with `fail`, `warn`, `at`, `each` and `include`,
  `ValidationReport`, `ValidationException`, `Violation`, `ViolationPath`, `ViolationCode` and
  `Severity`, and `validateAs` / `validateOrThrow` for values no builder assembled.
- Builder DSL: `Builder` and `ValidatingBuilder` with `nested`, `collect` and `adopt`, so nested
  blocks report every problem at once.
- Kotlin scope functions for configuration blocks: `apply`, `let`, `takeIf` and `takeUnless`.
- Program parameters (`package:essentia/arguments.dart`): `Parameters` schemas with flags,
  required, defaulted and repeatable parameters, conversions, validation, environment fallback,
  value sources, mutually exclusive groups, dependencies, deprecation warnings, masking of
  sensitive values and a usage listing.
- Event bus: `eventBus`, typed `TopicKey`s, partitions with per-key ordering, consumer groups,
  replay, overflow policies, headers, correlation and causation carried through a `Zone`,
  listeners, interceptors, metrics, `drain` and `dispose`.
- Layering contracts: `DomainModel`, `DataTransferObject`, `Mapper`, `DataSource`, `Repository`
  and `UseCase`.
- RFC 9562 identifiers: `UuidV4` and monotonic `UuidV7`.
- Platform detection: `Platform`, `OperatingSystem` and `Architecture`.
- Lifecycle contracts: `Disposable` and `DisposableAsync`.
- Inspectra 1.0.0 as the quality gate: format, lint, strict style, API dump, Trivy scans, coverage
  and changelog checks.

### Fixed

- A violation path, parameter signature or parameter name wider than its column is followed by one
  space instead of running into the message, annotations or value next to it (ARC-44).
