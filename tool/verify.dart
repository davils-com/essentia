/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:io';

/// The packages of the workspace that run on every platform, each tested
/// on the VM, in Chrome compiled to JavaScript and in Chrome compiled to
/// WebAssembly.
const packages = <String>[
  'essentia_core',
  'essentia_time',
  'essentia_coroutines',
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
    'essentia_core',
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
