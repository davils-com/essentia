/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/arguments/lex_result.dart';
import 'package:essentia/src/arguments/parameter_spec.dart';
import 'package:essentia/src/arguments/parameter_violation.dart';
import 'package:essentia/src/arguments/raw_occurrence.dart';
import 'package:essentia/src/arguments/suggestions.dart';
import 'package:essentia/src/arguments/unknown_argument_policy.dart';
import 'package:meta/meta.dart';

/// What reading one command line has found so far.
@internal
final class LexState {
  /// Creates the state of a pass knowing [_knownNames] and treating unknown
  /// arguments by [_policy].
  LexState(this._knownNames, this._policy);

  /// Every name a parameter answers to, for suggestions.
  final Iterable<String> _knownNames;

  /// What to do with an argument nobody declared.
  final UnknownArgumentPolicy _policy;

  /// The raw values by the ordinal of their parameter.
  final _occurrences = <int, List<RawOccurrence>>{};

  /// The arguments collected as unknown.
  final _unknown = <String>[];

  /// The arguments after the terminator.
  final _rest = <String>[];

  /// What could not be read.
  final _violations = <ParameterViolation>[];

  /// Records [raw] for [spec], given through [token].
  void record(ParameterSpec spec, String raw, String token) {
    _occurrences
        .putIfAbsent(spec.ordinal, () => <RawOccurrence>[])
        .add(RawOccurrence(raw, token));
  }

  /// Records [token], a name nobody declared.
  void reject(String token) {
    if (_policy == UnknownArgumentPolicy.collect) {
      _unknown.add(token);
      return;
    }
    _violations.add(UnknownArgument(token, closestName(token, _knownNames)));
  }

  /// Records [token], a bundle of short names of which [letter] is not
  /// declared, so that none of them is applied.
  void rejectBundle(String letter, String token) {
    if (_policy == UnknownArgumentPolicy.collect) {
      _unknown.add(token);
      return;
    }
    if (letter.length == token.length) {
      _violations.add(UnknownArgument(letter, null));
      return;
    }
    _violations.add(UnknownArgument(letter, null, bundle: token));
  }

  /// Records [token], a value with no parameter, at [position].
  void rejectValue(String token, int position) {
    if (_policy == UnknownArgumentPolicy.collect) {
      _unknown.add(token);
      return;
    }
    _violations.add(StrayValue(position));
  }

  /// Records [token] as malformed for [reason].
  void malformed(String token, String reason) {
    _violations.add(MalformedArgument(token, reason));
  }

  /// Records that [spec], named as [token], had no value following it.
  void missingValue(ParameterSpec spec, String token) {
    _violations.add(MissingParameterValue(spec.info, token));
  }

  /// Takes every argument of [argv] from [from] on, untouched.
  void takeRest(List<String> argv, int from) {
    _rest.addAll(argv.sublist(from));
  }

  /// What the pass found.
  ///
  /// Returns the result.
  LexResult result() => LexResult(
    Map<int, List<RawOccurrence>>.unmodifiable(_occurrences),
    List<String>.unmodifiable(_unknown),
    List<String>.unmodifiable(_rest),
    List<ParameterViolation>.unmodifiable(_violations),
  );
}
