/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:math';

import 'random_text.dart';

/// One set of values for a `SpellingParameters`, together with how to spell
/// them on a command line.
final class Assignment {
  /// Creates the assignment.
  const Assignment({
    required this.host,
    required this.port,
    required this.verbose,
    required this.archive,
    required this.colour,
    required this.tags,
    required this.trailing,
    required this.useShortForms,
    required this.useAttachedValues,
    required this.clusterFlags,
  });

  /// Draws an assignment from [random].
  factory Assignment.random(Random random) => Assignment(
    host: _word(random),
    port: random.nextInt(65536),
    verbose: random.nextBool(),
    archive: random.nextBool(),
    colour: random.nextBool(),
    tags: List<String>.generate(random.nextInt(4), (_) => _word(random)),
    trailing: List<String>.generate(random.nextInt(3), (_) => _word(random)),
    useShortForms: random.nextBool(),
    useAttachedValues: random.nextBool(),
    clusterFlags: random.nextBool(),
  );

  /// The value of `--host`.
  final String host;

  /// The value of `--port`.
  final int port;

  /// The value of `--verbose`.
  final bool verbose;

  /// The value of `--archive`.
  final bool archive;

  /// The value of `--colour`.
  final bool colour;

  /// The values of `--tag`.
  final List<String> tags;

  /// What follows the `--` terminator.
  final List<String> trailing;

  /// Whether the short names are used.
  final bool useShortForms;

  /// Whether values are attached with an equals sign.
  final bool useAttachedValues;

  /// Whether the short flags are bundled with the port, where possible.
  final bool clusterFlags;

  /// Returns this assignment spelt with or without the short forms
  /// [useShortForms] and the attached values [useAttachedValues].
  Assignment respelt({bool? useShortForms, bool? useAttachedValues}) =>
      Assignment(
        host: host,
        port: port,
        verbose: verbose,
        archive: archive,
        colour: colour,
        tags: tags,
        trailing: trailing,
        useShortForms: useShortForms ?? this.useShortForms,
        useAttachedValues: useAttachedValues ?? this.useAttachedValues,
        clusterFlags: clusterFlags,
      );

  /// Renders the assignment as a command line.
  ///
  /// Returns the arguments.
  List<String> render() {
    final bool clustered = clusterFlags && useShortForms && verbose && archive;
    return <String>[
      ..._renderFlags(clustered: clustered),
      ..._named(_form('-h', '--host'), host),
      if (!clustered) ..._named(_form('-p', '--port'), '$port'),
      for (final tag in tags) ..._named(_form('-t', '--tag'), tag),
      if (trailing.isNotEmpty) ...<String>['--', ...trailing],
    ];
  }

  /// Renders the flags, bundled with the port when [clustered].
  ///
  /// Returns the arguments.
  List<String> _renderFlags({required bool clustered}) {
    if (clustered) {
      return <String>['-vap', '$port', _colourFlag];
    }
    return <String>[
      if (verbose) _form('-v', '--verbose'),
      if (archive) _form('-a', '--archive'),
      _colourFlag,
    ];
  }

  /// The colour flag, negated when the colour is off.
  String get _colourFlag => colour ? '--colour' : '--no-colour';

  /// Picks [short] or [long], whichever form is used.
  ///
  /// Returns the name.
  String _form(String short, String long) => useShortForms ? short : long;

  /// Spells [name] with [value], attached or separated.
  ///
  /// Returns the arguments.
  List<String> _named(String name, String value) =>
      useAttachedValues ? <String>['$name=$value'] : <String>[name, value];

  /// Draws a word of letters and digits from [random].
  ///
  /// Returns the word.
  static String _word(Random random) =>
      randomText(random, alphanumerics, minimum: 1, maximum: 12);
}
