# Essentia Core

The building blocks of [Essentia](https://github.com/davils-com/essentia#readme): validation that
reports every problem at once, validating configuration builders, program parameters, layering
contracts, RFC 9562 identifiers, semantic versions, principals, platform detection, byte strings
and hexadecimal formats, charsets, typed attributes, a case insensitive map, decimals, ranges,
regular expressions matched in linear time, a `Result` type, `lazy`, the `Duration` extensions and
extensions on Dart's own classes.

```dart
import 'package:essentia_core/essentia_core.dart';
```

Its only runtime dependency is `package:meta`. It runs on every Dart platform, the web and
WebAssembly included; `file()` is offered where `dart:io` is.

## Regular expressions in linear time

```dart
final pattern = LinearRegExp(r'^[a-z]+(-[a-z]+)*$');
final bool valid = pattern.hasMatch('two-words');
```

A `RegExp` backtracks, so a pattern such as `(a+)+$` takes time exponential in the length of a text
it does not match. `LinearRegExp` follows every way through the pattern at once: a
match costs at most the code points of the text times `instructionCount`. It reads the syntax of
ECMAScript in its unicode mode and refuses, with a `LinearRegExpException` naming the reason and
the offset, a backreference, a lookahead or lookbehind, and a pattern that compiles to more than
`maxInstructions` instructions. It has no flags and answers only whether the pattern matches
somewhere in a text. It is here for the patterns of documents nobody trusts.

## License

Apache 2.0 - see [LICENSE](LICENSE).
