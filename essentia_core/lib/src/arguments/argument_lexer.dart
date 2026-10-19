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

import 'package:essentia_core/src/arguments/lex_result.dart';
import 'package:essentia_core/src/arguments/lex_state.dart';
import 'package:essentia_core/src/arguments/name_match.dart';
import 'package:essentia_core/src/arguments/parameter_spec.dart';
import 'package:essentia_core/src/arguments/unknown_argument_policy.dart';
import 'package:meta/meta.dart';

/// Reads a command line into raw values per parameter, without converting
/// anything.
///
/// Long names take their value as `--name=value` or as the next argument;
/// short names may be bundled (`-vx`) and take a value attached (`-p8080`,
/// `-p=8080`) or as the next argument. `--` ends the parameters, and
/// everything after it is handed back untouched.
@internal
final class ArgumentLexer {
  /// Creates a lexer for [specs], treating unknown arguments by [_policy].
  ArgumentLexer(List<ParameterSpec> specs, this._policy)
    : _matches = _buildIndex(specs);

  /// The prefix of a long name, and the terminator.
  static const _longPrefix = '--';

  /// The prefix of a short name.
  static const _shortPrefix = '-';

  /// What separates a name from an attached value.
  static const _valueSeparator = '=';

  /// What to do with an argument nobody declared.
  final UnknownArgumentPolicy _policy;

  /// Every name a parameter answers to.
  final Map<String, NameMatch> _matches;

  /// Reads [argv].
  ///
  /// Returns what was found.
  LexResult lex(List<String> argv) {
    final state = LexState(_matches.keys, _policy);
    var index = 0;
    while (index < argv.length) {
      if (argv[index] == _longPrefix) {
        state.takeRest(argv, index + 1);
        return state.result();
      }
      index = _readToken(argv, index, state);
    }
    return state.result();
  }

  /// Reads the argument at [index].
  ///
  /// Returns the index of the next argument to read.
  int _readToken(List<String> argv, int index, LexState state) {
    final String token = argv[index];
    if (token.startsWith(_longPrefix)) {
      return _readLong(argv, index, state);
    }
    final bool isShort =
        token.startsWith(_shortPrefix) && token.length > _shortPrefix.length;
    if (isShort) {
      return _readShort(argv, index, state);
    }
    state.rejectValue(token, index + 1);
    return index + 1;
  }

  /// Reads the long name at [index].
  ///
  /// Returns the index of the next argument to read.
  int _readLong(List<String> argv, int index, LexState state) {
    final String token = argv[index];
    final int separator = token.indexOf(_valueSeparator);
    final String name = separator < 0 ? token : token.substring(0, separator);
    final String? inlineValue = separator < 0
        ? null
        : token.substring(separator + 1);
    if (name.length <= _longPrefix.length) {
      state.malformed(name, 'has no parameter name');
      return index + 1;
    }
    final NameMatch? match = _matches[name];
    if (match == null) {
      state.reject(name);
      return index + 1;
    }
    if (match.negated && inlineValue != null) {
      state.malformed(name, 'is a negated flag and does not take a value');
      return index + 1;
    }
    return _consumeLong(argv, index, match, inlineValue, state);
  }

  /// Records the value of the long name [match] at [index].
  ///
  /// Returns the index of the next argument to read.
  int _consumeLong(
    List<String> argv,
    int index,
    NameMatch match,
    String? inlineValue,
    LexState state,
  ) {
    final ParameterSpec spec = match.spec;
    final String token = argv[index];
    if (spec.info.isFlag) {
      state.record(spec, inlineValue ?? '${!match.negated}', token);
      return index + 1;
    }
    if (inlineValue != null) {
      state.record(spec, inlineValue, token);
      return index + 1;
    }
    return _takeFollowingValue(argv, index, spec, spec.info.primaryName, state);
  }

  /// Reads the short names bundled at [index].
  ///
  /// A bundle is one decision: when one of its letters is not declared,
  /// none of them is applied.
  ///
  /// Returns the index of the next argument to read.
  int _readShort(List<String> argv, int index, LexState state) {
    final String token = argv[index];
    final String body = token.substring(_shortPrefix.length);
    final String? undeclared = _firstUndeclaredLetter(body);
    if (undeclared != null) {
      state.rejectBundle(undeclared, token);
      return index + 1;
    }
    for (var position = 0; position < body.length; position++) {
      final name = '$_shortPrefix${body[position]}';
      final NameMatch match = _matches[name]!;
      final String remainder = body.substring(position + 1);
      final ParameterSpec spec = match.spec;
      if (!spec.info.isFlag) {
        return _consumeShortValue(argv, index, spec, name, remainder, state);
      }
      if (remainder.startsWith(_valueSeparator)) {
        state.record(spec, remainder.substring(1), token);
        return index + 1;
      }
      state.record(spec, 'true', token);
    }
    return index + 1;
  }

  /// Finds the first letter of the bundle [body] that names no parameter,
  /// up to where the bundle ends in a value.
  ///
  /// Returns the letter as a short name, or `null` when every letter is
  /// declared.
  String? _firstUndeclaredLetter(String body) {
    for (var position = 0; position < body.length; position++) {
      final name = '$_shortPrefix${body[position]}';
      final NameMatch? match = _matches[name];
      if (match == null) {
        return name;
      }
      if (_endsTheBundle(match, body, position)) {
        return null;
      }
    }
    return null;
  }

  /// Whether the letter at [position] of [body], matching [match], is the
  /// last one of the bundle because what follows it is a value.
  static bool _endsTheBundle(NameMatch match, String body, int position) {
    if (!match.spec.info.isFlag) {
      return true;
    }
    final int next = position + 1;
    return next < body.length && body[next] == _valueSeparator;
  }

  /// Records the value of the short name [name] at [index], attached as
  /// [remainder] or following it.
  ///
  /// Returns the index of the next argument to read.
  int _consumeShortValue(
    List<String> argv,
    int index,
    ParameterSpec spec,
    String name,
    String remainder,
    LexState state,
  ) {
    if (remainder.isEmpty) {
      return _takeFollowingValue(argv, index, spec, name, state);
    }
    final String attached = remainder.startsWith(_valueSeparator)
        ? remainder.substring(1)
        : remainder;
    state.record(spec, attached, name);
    return index + 1;
  }

  /// Records the argument after [index] as the value of [spec].
  ///
  /// Returns the index of the next argument to read.
  int _takeFollowingValue(
    List<String> argv,
    int index,
    ParameterSpec spec,
    String token,
    LexState state,
  ) {
    final bool hasNext = index + 1 < argv.length;
    if (!hasNext || !_looksLikeValue(argv[index + 1])) {
      state.missingValue(spec, token);
      return index + 1;
    }
    state.record(spec, argv[index + 1], token);
    return index + 2;
  }

  /// Whether [token] is a value rather than a name: anything not starting
  /// with a dash, a lone dash, and a negative number.
  static bool _looksLikeValue(String token) {
    if (!token.startsWith(_shortPrefix) || token == _shortPrefix) {
      return true;
    }
    return double.tryParse(token.substring(_shortPrefix.length)) != null;
  }

  /// Maps every name of [specs], negated ones included, to its parameter.
  ///
  /// Returns the index.
  static Map<String, NameMatch> _buildIndex(List<ParameterSpec> specs) {
    final index = <String, NameMatch>{};
    for (final spec in specs) {
      for (final String name in spec.info.names) {
        index[name] = NameMatch(spec, negated: false);
      }
      for (final String name in spec.negatedNames()) {
        index[name] = NameMatch(spec, negated: true);
      }
    }
    return Map<String, NameMatch>.unmodifiable(index);
  }
}
