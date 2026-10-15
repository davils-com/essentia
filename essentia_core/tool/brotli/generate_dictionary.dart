/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:convert';
import 'dart:io';

/// The static dictionary of RFC 7932 Appendix A, as google/brotli 1.1.0
/// ships it in `c/common/dictionary.bin`, beside its MIT `LICENSE`.
const source = 'tool/brotli/dictionary.bin';

/// The generated file.
const output = 'lib/src/bytes/compression/brotli/brotli_dictionary_data.dart';

/// The length of the dictionary RFC 7932 gives.
const dictionaryLength = 122784;

/// How many characters of Base64 one string literal holds.
const _chunk = 72;

/// Compiles the static dictionary of Brotli into [output], or with
/// `--check` only tells whether [output] is current, exiting with 1 when
/// it is not.
void main(List<String> arguments) {
  final bool check = arguments.contains('--check');
  final List<int> dictionary = File(source).readAsBytesSync();
  if (dictionary.length != dictionaryLength) {
    stderr.writeln(
      '$source holds ${dictionary.length} bytes, not $dictionaryLength.',
    );
    exitCode = 1;
    return;
  }
  final String generated = render(dictionary);
  final file = File(output);
  if (!check) {
    file.writeAsStringSync(generated);
    stdout.writeln('Wrote $output.');
    return;
  }
  if (!file.existsSync() || file.readAsStringSync() != generated) {
    stderr.writeln(
      '$output is out of date: run dart run tool/brotli/generate_dictionary.dart',
    );
    exitCode = 1;
    return;
  }
  stdout.writeln('$output is current.');
}

/// The Dart source of [dictionary], as `dart format` leaves it.
///
/// Returns it.
String render(List<int> dictionary) {
  final String data = base64.encode(dictionary);
  final out = StringBuffer()
    ..writeln(
      File('../tool/license_header.txt')
          .readAsStringSync()
          .replaceAll('{year}', '2026'),
    )
    ..writeln(
      '/// The static dictionary of Brotli, RFC 7932 Appendix A, generated',
    )
    ..writeln('/// by `tool/brotli/generate_dictionary.dart` from')
    ..writeln('/// `tool/brotli/dictionary.bin` of google/brotli. Do not edit.')
    ..writeln('@internal')
    ..writeln('library;')
    ..writeln()
    ..writeln("import 'package:meta/meta.dart';")
    ..writeln()
    ..writeln('/// The $dictionaryLength bytes of the dictionary, in Base64.')
    ..writeln('const brotliDictionaryData =');
  for (var start = 0; start < data.length; start += _chunk) {
    final int end = start + _chunk > data.length ? data.length : start + _chunk;
    final terminator = end == data.length ? ';' : '';
    out.writeln("    '${data.substring(start, end)}'$terminator");
  }
  return out.toString();
}
