/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:convert';
import 'dart:io';

/// The static dictionary of RFC 7932 Appendix A, 122784 bytes.
const source = 'tool/brotli/dictionary.bin';

/// The generated file.
const output = 'lib/src/brotli/brotli_dictionary_data.dart';

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
    ..writeln('/// `tool/brotli/dictionary.bin`. Do not edit.')
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
