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

import 'dart:io';

/// The packages of the workspace that run on every platform, each tested
/// on the VM, in Chrome compiled to JavaScript and in Chrome compiled to
/// WebAssembly.
const packages = <String>[
  'essentia_core',
  'essentia_compression',
  'essentia_time',
  'essentia_coroutines',
  'essentia_io',
];

/// The steps of `dart run tool/verify.dart`, in order.
///
/// Returns every step: a label, the directory it runs in, relative to the
/// workspace root, and the `dart` arguments that run it.
List<(String, String, List<String>)>
steps() => <(String, String, List<String>)>[
  (
    'Format',
    '.',
    <String>['format', '--output=none', '--set-exit-if-changed', '.'],
  ),
  ('Analyze', '.', <String>['analyze', '--fatal-infos']),
  ('Style', '.', <String>['run', 'inspectra', 'style']),
  for (final String package in packages)
    ('Style $package', package, <String>['run', 'inspectra', 'style']),
  (
    'Generated Brotli dictionary',
    'essentia_compression',
    <String>['run', 'tool/brotli/generate_dictionary.dart', '--check'],
  ),
  (
    'Generated time zones',
    'essentia_time',
    <String>['run', 'tool/generate_tzdata.dart', '--check'],
  ),
  for (final String package in packages) ...<(String, String, List<String>)>[
    ('Test $package (VM)', package, <String>['test']),
    ('Test $package (web)', package, <String>['test', '--platform', 'chrome']),
    (
      'Test $package (WebAssembly)',
      package,
      <String>['test', '--platform', 'chrome', '--compiler', 'dart2wasm'],
    ),
  ],
];

/// Runs every verification step of the workspace and stops at the first
/// failure, exiting with that step's exit code.
///
/// The steps run in the workspace root, the directory above this script,
/// wherever the command was started.
///
/// This is the single command to run before every push; CI runs exactly the
/// same, followed by `dart run inspectra -C <package> check` for every
/// package and `dart run inspectra check` at the root.
Future<void> main() async {
  final String dart = Platform.resolvedExecutable;
  final Directory root = File.fromUri(Platform.script).parent.parent;
  for (final (label, directory, arguments) in steps()) {
    stdout.writeln('==> $label: dart ${arguments.join(' ')}');
    final Process process = await Process.start(
      dart,
      arguments,
      workingDirectory: '${root.path}/$directory',
      mode: ProcessStartMode.inheritStdio,
    );
    final int code = await process.exitCode;
    if (code != 0) {
      stderr.writeln('==> $label failed with exit code $code.');
      exitCode = code;
      return;
    }
  }
  stdout.writeln('==> All checks passed.');
}
