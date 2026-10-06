/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:io';

/// The steps of `dart run tool/verify.dart`, in order: a label and the
/// `dart` arguments that run it.
const steps = <(String, List<String>)>[
  ('Format', <String>['format', '--output=none', '--set-exit-if-changed', '.']),
  ('Analyze', <String>['analyze', '--fatal-infos']),
  ('Style', <String>['run', 'inspectra', 'style']),
  ('Test (VM)', <String>['test']),
  ('Test (web)', <String>['test', '--platform', 'chrome']),
  (
    'Test (WebAssembly)',
    <String>['test', '--platform', 'chrome', '--compiler', 'dart2wasm'],
  ),
];

/// Runs every verification step of the repository and stops at the first
/// failure, exiting with that step's exit code.
///
/// This is the single command to run before every push; CI runs exactly the
/// same, followed by `dart run inspectra check`.
Future<void> main() async {
  final String dart = Platform.resolvedExecutable;
  for (final (label, arguments) in steps) {
    stdout.writeln('==> $label: dart ${arguments.join(' ')}');
    final Process process = await Process.start(
      dart,
      arguments,
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
