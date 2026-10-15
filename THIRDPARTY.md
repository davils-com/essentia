# Third-Party Software

This document lists the third-party software Essentia uses or integrates with.

---

## Runtime

- [meta](https://pub.dev/packages/meta) - the `@internal`, `@protected` and `@visibleForTesting`
  annotations, licensed under the
  [BSD 3-Clause License](https://github.com/dart-lang/sdk/blob/main/pkg/meta/LICENSE). It is the only
  package a consumer of Essentia resolves.

## Bundled data

- [The IANA time zone database](https://www.iana.org/time-zones), release 2026e, in
  `essentia_time/IANA/tzdata/2026e`, compiled into `essentia_time/lib/src/internal/tzdata.dart` by
  `essentia_time/tool/generate_tzdata.dart`. Its data is in the public domain, as its `LICENSE` file says.

- The Unicode character data of the Unicode Character Database of the Python that runs
  `essentia_core/tool/unicode/generate_normalization.py`, compiled into
  `essentia_core/lib/src/text/internal/`. Licensed under the
  [Unicode License v3](https://www.unicode.org/license.txt).

- The static dictionary of Brotli, RFC 7932 Appendix A, as
  [google/brotli](https://github.com/google/brotli) 1.1.0 ships it in `c/common/dictionary.bin`, in
  `essentia_core/tool/brotli/dictionary.bin`, compiled into
  `essentia_core/lib/src/bytes/compression/brotli/brotli_dictionary_data.dart` by
  `essentia_core/tool/brotli/generate_dictionary.dart`. Licensed under the
  [MIT License](https://github.com/google/brotli/blob/master/LICENSE), whose notice is at the end
  of this document.
- The test vectors of [google/brotli](https://github.com/google/brotli) 1.1.0, `tests/testdata`, in
  `essentia_core/test/fixtures/brotli`, used only by the tests. Licensed under the
  [MIT License](https://github.com/google/brotli/blob/master/LICENSE), whose notice is at the end
  of this document.

## Development

- [Inspectra](https://pub.dev/packages/inspectra) - the quality gates, the style rules and the
  supply-chain scans, licensed
  under the [Apache License 2.0](https://github.com/davils-com/Inspectra/blob/main/LICENSE).
- [test](https://pub.dev/packages/test) - the test runner on the VM, in Chrome and in WebAssembly,
  licensed under the [BSD 3-Clause License](https://github.com/dart-lang/test/blob/master/pkgs/test/LICENSE).
- [Trivy](https://github.com/aquasecurity/trivy) - vulnerability, secret, misconfiguration and license
  scanner, licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
  Inspectra downloads, verifies and runs the unmodified official release.

## Reference

- [Arc](https://gitlab.davils.com/davils/libraries/arc) - the Davils application runtime core for
  Kotlin, of which Essentia is the Dart port.

## Notices

### google/brotli

The static dictionary and the test vectors of Brotli carry this notice:

```text
Copyright (c) 2009, 2010, 2013-2016 by the Brotli Authors.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```
