# Security Policy

## Reporting a Vulnerability

**Do not open a public issue for a security problem.**

Report it privately by email to development@davils.com.

Please include:

- the affected Essentia version, the Dart SDK and the platform you are running on - the VM,
  Flutter, the web or WebAssembly,
- a description of the impact - what an attacker gains,
- the steps to reproduce it, ideally as a minimal schema and a single `load` call, or a minimal
  bus declaration and one `publish`,
- any mitigation you are already aware of.

## Scope

Essentia runs during startup and inside the process: it handles the arguments a program was
started with, the values a program marks as secret, the principal a piece of work runs as, and the
events passed between parts of a program. Its threat model follows from that.

The following are **in scope**:

- **Leakage of a value marked sensitive.** A `.sensitive()` parameter appearing in clear text in
  anything Essentia renders - `describe()`, `usage()`, a `ParameterException` message, a
  `ValidationReport`, or a `toString` anywhere on the path. This includes the case where the
  sensitive value is what failed: a conversion or validation message must never echo it.
- **Leakage through a violation.** A `Violation` carrying a secret in its message or path, or a
  built-in converter quoting the rejected value where the parameter was marked sensitive.
- **Leakage of a principal or an event.** A masked attribute of a `Principal` rendered in clear
  text, or an envelope rendering the content of its payload instead of its type.
- **Credentials reaching a value source.** A path by which a `ValueSource` is handed a value, a
  name or a context it should not see, or by which what it returned is rendered unmasked.
- **Resolution being made to disagree with itself.** Any input that makes a parameter read a value
  other than the one the declared precedence selects - a crafted argument that shadows an
  environment variable, or a parameter reading another parameter's value.
- **The wrong principal.** Work running as, or an envelope carrying, a principal other than the one
  the `Zone` of the publisher or of `runAsPrincipal` established.
- **Denial of service.** Non-linear behaviour in the argument lexer, the suggestion matcher, a
  converter, the semantic version parser or the range algebra, and keys chosen to collide so that
  every envelope of a topic lands on one partition.
- **Predictable identifiers.** A `UuidV4` or `UuidV7` whose random bits do not come from
  `Random.secure()`.

The following are **not** vulnerabilities in Essentia:

- An application printing a parameter it never marked `.sensitive()`. Essentia masks what it is
  told to mask; deciding what is secret is the application's job.
- What an application does with a converted value. `path()` and `file()` check existence and
  readability because a startup failure is more useful than a later one; they are not a sandbox,
  and Essentia never opens what it converted.
- A `ValueSource`, `Converter`, validation rule, event consumer or interceptor written by a
  consumer. Code passed into Essentia runs with the application's privileges and is trusted by
  definition.
- Anything an attacker can only reach by already controlling the program's arguments **and** its
  schema. A schema is Dart source; an attacker who can change it does not need a vulnerability.
- The event bus being in-process and not durable. An envelope lives in memory, is delivered at most
  once and is never written down; that is its contract, not a weakness.
- Reading a parameter before `load`. That is a defect in the program's startup order, reported as
  `ParametersNotLoadedError`, and it fails closed.

## Hardening Notes for Consumers

- Mark every credential `.sensitive()`. It is the only thing that makes `describe()` safe to write
  to a startup log, and it keeps the value out of a failure report about that same value.
- Prefer the environment or a `ValueSource` over the command line for secrets. A process argument
  list is readable by any process of the same user on a typical Linux host; an environment variable
  is not, and a secret store is not.
- Keep `UnknownArgumentPolicy.reject`, which is the default. Collecting unknown arguments and passing
  them to a child process forwards whatever was supplied, including arguments meant for something
  else.
- Treat `rest` and `unknown` as untrusted. Essentia hands them over verbatim; it neither inspects
  nor escapes them.
- Mark the attributes of a principal that carry personal data as sensitive before anything logs the
  principal or an envelope published as it.
- Do not log a `ValidationReport` from a builder whose data holds secrets unless those fields are
  excluded from the messages. Masking is a parameter feature; a builder's rules write whatever
  they write.

## Build Integrity

What Essentia's own build resolves is constrained and scanned by
[Inspectra](https://pub.dev/packages/inspectra) on every `dart run inspectra check`:

- The dependency policy requires an upper bound on every constraint, a local `pubspec.lock` that
  matches `pubspec.yaml`, and a SHA-256 checksum for every hosted package in it.
- Trivy 0.75.0, which Inspectra downloads and verifies against the official `checksums.txt`, scans
  the dependencies for known vulnerabilities and licenses, and the repository for secrets and
  misconfigurations, at every severity. The rules of [trivy-secret.yaml](trivy-secret.yaml) add
  hard-coded credentials in Dart and cover Markdown as well.
- No finding can be ignored or recorded in a baseline, and the `policy` of the configuration keeps
  `INSPECTRA_*` variables and the command line from weakening any of it.

**Essentia does not commit `pubspec.lock`.** It is a library, so a consumer resolves its own
versions; a consumer that needs the bytes of every package pinned commits its own lockfile and
resolves through a repository manager that enforces it.
